import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/rutina/sesion.dart';

class SesionMusculosInvolucradosPage extends ConsumerStatefulWidget {
  final Sesion sesion;

  const SesionMusculosInvolucradosPage({
    Key? key,
    required this.sesion,
  }) : super(key: key);

  @override
  ConsumerState<SesionMusculosInvolucradosPage> createState() => _SesionMusculosInvolucradosPageState();
}

class _SesionMusculosInvolucradosPageState extends ConsumerState<SesionMusculosInvolucradosPage> {
  bool _showFrontImage = true;

  @override
  Widget build(BuildContext context) {
    final sesion = widget.sesion;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: sesion.getMusculosInvoluracion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final musculos = snapshot.data ?? [];
        // Calcular el porcentaje máximo real
        double maxPercentage = musculos.fold(0.0, (prev, m) {
          final value = double.tryParse(m['porcentaje']?.toString() ?? '0') ?? 0.0;
          return value > prev ? value : prev;
        });
        if (maxPercentage == 0) maxPercentage = 1; // Evitar división por cero

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            return Container(
              color: AppColors.background,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna izquierda: imagen principal y leyenda (65% del ancho)
                  Container(
                    width: availableWidth * 0.65,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _showFrontImage
                                ? Image.asset(
                                    'assets/images/cuerpohumano/cuerpohumano-frontal.png',
                                    key: const ValueKey('front'),
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'assets/images/cuerpohumano/cuerpohumano-back.png',
                                    key: const ValueKey('back'),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const LegendWidget(),
                      ],
                    ),
                  ),
                  // Columna derecha: listado de músculos (35% del ancho)
                  Container(
                    width: availableWidth * 0.35,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: musculos.length,
                          itemBuilder: (context, index) {
                            final m = musculos[index];
                            if (m == null) return const SizedBox.shrink();
                            return MusclesListWidget(
                              musculo: m,
                              maxPercentage: maxPercentage,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class MusclesListWidget extends StatelessWidget {
  final Map<String, dynamic> musculo;
  final double maxPercentage;

  const MusclesListWidget({
    Key? key,
    required this.musculo,
    required this.maxPercentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nombre = musculo['musculo'] ?? 'Desconocido';
    final porcentaje = double.tryParse(musculo['porcentaje']?.toString() ?? '0') ?? 0.0;
    final capitalizedMuscle = nombre.isNotEmpty ? nombre[0].toUpperCase() + nombre.substring(1) : nombre;

    // Normalizar según el máximo real
    final normalized = porcentaje / maxPercentage;
    // Lógica de grupos:
    // Alta participación: normalized ≥ 0.60, Media participación: 0.35 ≤ normalized < 0.60, Baja participación: normalized < 0.35.
    Color barColor;
    if (normalized >= 0.60) {
      barColor = AppColors.mutedAdvertencia;
    } else if (normalized >= 0.35) {
      barColor = Colors.green;
    } else {
      barColor = Colors.red;
    }

    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: barColor.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              capitalizedMuscle,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: porcentaje / 100,
                      backgroundColor: barColor.withAlpha(40),
                      valueColor: AlwaysStoppedAnimation<Color>(barColor.withAlpha(130)),
                    ),
                  ),
                ),
                Text(
                  '${porcentaje.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.textNormal,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LegendWidget extends StatelessWidget {
  const LegendWidget({Key? key}) : super(key: key);

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8, // Separa verticalmente las líneas de la leyenda
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem(AppColors.mutedAdvertencia, 'Principales'),
        _buildLegendItem(Colors.green, 'Secundarios'),
        _buildLegendItem(Colors.red, 'Residuales'),
      ],
    );
  }
}
