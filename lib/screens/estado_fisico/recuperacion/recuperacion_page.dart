import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/screens/estado_fisico/recuperacion/musculo_detalle.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/models/modelo_datos.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/utils/colors.dart';

class RecuperacionPage extends ConsumerStatefulWidget {
  const RecuperacionPage({super.key});

  @override
  ConsumerState<RecuperacionPage> createState() => _RecuperacionPageState();
}

class _RecuperacionPageState extends ConsumerState<RecuperacionPage> {
  bool _showFrontImage = true;
  bool _isLoading = true;
  bool _imagesCached = false;
  List<Entrenamiento> _resumenEntrenamientos = [];
  Map<String, Map<String, dynamic>> _musculosRecuperacion = {};

  double? _realHeight;
  dynamic _realWeight;

  @override
  void initState() {
    super.initState();
    _cargarDisponibilidadMuscular();
    _cargarHealthData();
  }

  void _cargarHealthData() async {
    final usuario = ref.read(usuarioProvider);
    final heightData = await usuario.getReadHeight(9999);
    final weightData = await usuario.getReadWeight(9999);
    setState(() {
      _realHeight = heightData.isNotEmpty ? (heightData.values.last is int ? (heightData.values.last as int).toDouble() : heightData.values.last) : null;
      _realWeight = weightData.isNotEmpty ? weightData.values.last : null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesCached) {
      precacheImage(const AssetImage('assets/images/cuerpohumano/cuerpohumano-frontal.png'), context);
      precacheImage(const AssetImage('assets/images/cuerpohumano/cuerpohumano-back.png'), context);
      _imagesCached = true;
    }
  }

  void _toggleImage() {
    setState(() {
      _showFrontImage = !_showFrontImage;
    });
  }

  void _cargarDisponibilidadMuscular() async {
    setState(() {
      _isLoading = true;
    });

    final usuario = ref.read(usuarioProvider);
    final entrenamientos = await usuario.getEjerciciosLastDias(5) ?? [];
    for (final e in entrenamientos) {
      await e.calcularRecuperacion(usuario);
    }
    final Map<String, double> gastoPorMusculo = await usuario.getGastoActualPorMusculoPorcentaje(entrenamientos, usuario);

    final Map<String, Map<String, dynamic>> resultado = {};
    gastoPorMusculo.forEach((musculo, gasto) {
      final recuperacion = 100 - gasto;
      resultado[musculo] = {'pct': recuperacion};
    });

    // Completar músculos faltantes usando ModeloDatos.getMusculos
    final modelo = ModeloDatos();
    final todosMusculos = await modelo.getMusculos();
    if (todosMusculos != null) {
      for (final musculo in todosMusculos) {
        final nombreMusculo = (musculo['titulo'] as String).toLowerCase();
        if (!resultado.containsKey(nombreMusculo)) {
          resultado[nombreMusculo] = {'pct': 100.0};
        }
      }
    }

    final sortedEntries = resultado.entries.toList()..sort((a, b) => (a.value['pct'] as double).compareTo(b.value['pct'] as double));

    setState(() {
      _musculosRecuperacion = {for (var e in sortedEntries) e.key: e.value};
      _resumenEntrenamientos = entrenamientos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recuperación"), // Title "Recuperación"
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back arrow
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen y datos de altura/peso
                Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(10),
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 50),
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
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: AppColors.accentColor.withAlpha(180),
                                child: IconButton(
                                  onPressed: _toggleImage,
                                  icon: const Icon(Icons.refresh, color: AppColors.textNormal),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accentColor, width: 2.0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _realHeight != null ? '${_realHeight!.toInt()} cm' : '...',
                            style: TextStyle(fontSize: 35, color: AppColors.accentColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accentColor, width: 2.0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _realWeight != null ? '${_realWeight!.toStringAsFixed(1)} kg' : '...',
                            style: TextStyle(fontSize: 35, color: AppColors.accentColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Lista de músculos y % de recuperación en 2 columnas
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : LayoutBuilder(builder: (context, constraints) {
                            // Calculamos el ancho disponible para cada ítem
                            final muscleItemWidth = (constraints.maxWidth - 10) / 2;
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _musculosRecuperacion.entries.where((entry) => entry.key != 'otros').map((entry) {
                                final pct = (entry.value['pct'] ?? 0.0).toDouble();
                                final capitalizedMuscle = entry.key.isNotEmpty ? entry.key[0].toUpperCase() + entry.key.substring(1) : entry.key;
                                // Lógica de color:
                                // 0-25%: mutedRed
                                // 25-60%: interpolar entre mutedRed y advertencia
                                // 60-100%: interpolar entre advertencia y accentColor
                                Color barColor;
                                if (pct <= 25) {
                                  barColor = AppColors.mutedRed;
                                } else if (pct <= 60) {
                                  final double ratio = (pct - 25) / 35; // 0 a 1 cuando pct va de 25 a 60
                                  barColor = Color.lerp(AppColors.mutedRed, AppColors.mutedAdvertencia, ratio) ?? AppColors.mutedRed;
                                } else {
                                  final double ratio = (pct - 60) / 40; // 0 a 1 cuando pct va de 60 a 100
                                  barColor = Color.lerp(AppColors.mutedAdvertencia, AppColors.accentColor, ratio) ?? AppColors.mutedAdvertencia;
                                }
                                return SizedBox(
                                  width: muscleItemWidth,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MusculoDetallePage(
                                            musculo: entry.key,
                                            entrenamientos: _resumenEntrenamientos,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 5),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentColor.withAlpha(50),
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
                                                    value: pct / 100,
                                                    backgroundColor: barColor.withAlpha(40),
                                                    valueColor: AlwaysStoppedAnimation<Color>(barColor.withAlpha(130)),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${pct.toStringAsFixed(0)}%',
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
                                  ),
                                );
                              }).toList(),
                            );
                          }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
