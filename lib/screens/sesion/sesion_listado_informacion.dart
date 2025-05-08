import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/rutina/rutina.dart';
import 'package:mrfit/models/rutina/grupo.dart';
import 'package:intl/intl.dart';
import 'package:mrfit/widgets/chart/pills_dificultad.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mrfit/widgets/chart/grafica.dart';

class SesionListadoInformacionPage extends StatefulWidget {
  final Rutina rutina;
  const SesionListadoInformacionPage({Key? key, required this.rutina}) : super(key: key);

  @override
  _SesionListadoInformacionState createState() => _SesionListadoInformacionState();
}

// Clase interna para los datos de la serie temporal
class _ChartEntry {
  final DateTime dia;
  final int cantidad;
  _ChartEntry(this.dia, this.cantidad);
}

class _SesionListadoInformacionState extends State<SesionListadoInformacionPage> {
  // NUEVAS PROPIEDADES
  int totalEntrenos = 0;
  int tiempoTotalSeg = 0;
  double duracionMediaSeg = 0;
  int totalSets = 0;
  List<Map<String, Object?>> chartData = [];
  List<FlSpot> spots = [];
  List<DateTime> dates = [];
  Grupo? grupo;

  @override
  void initState() {
    super.initState();
    _loadEstadisticas();
  }

  Future<void> _loadEstadisticas() async {
    final rut = widget.rutina;
    final t1 = await rut.getTotalEntrenamientos();
    final t2 = await rut.getTiempoTotalSegundos();
    final t3 = await rut.getDuracionMediaSegundos();
    final t4 = await rut.getTotalSetsCompletados();
    final ch = await rut.getVolumenPorEntrenamiento();
    final g = await Grupo.loadById(widget.rutina.grupoId);
    setState(() {
      totalEntrenos = t1;
      tiempoTotalSeg = t2;
      duracionMediaSeg = t3;
      totalSets = t4;
      chartData = ch;
      // genera puntos y fechas basados en volumen
      spots = chartData.asMap().entries.map((e) {
        return FlSpot(
          e.key.toDouble(),
          (e.value['volumen_total'] as num).toDouble(),
        );
      }).toList();
      dates = chartData.map((m) => DateTime.parse(m['inicio'] as String)).toList();
      grupo = g; // <--- asignación
    });
  }

  @override
  Widget build(BuildContext context) {
    final fecha = widget.rutina.fechaCreacion != null ? DateFormat('dd/MM/yyyy').format(widget.rutina.fechaCreacion!.toLocal()) : 'N/A';
    return SingleChildScrollView(
      child: Column(
        children: [
          // ESTADÍSTICAS en “pills”
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pillWidth = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPill('Total entrenamientos', Text('$totalEntrenos', style: _pillValueStyle), pillWidth),
                    _buildPill('Tiempo total', Text(_formatDuration(Duration(seconds: tiempoTotalSeg)), style: _pillValueStyle), pillWidth),
                    _buildPill('Duración media', Text(_formatDuration(Duration(seconds: duracionMediaSeg.round())), style: _pillValueStyle), pillWidth),
                    _buildPill('Sets completados', Text('$totalSets', style: _pillValueStyle), pillWidth),
                  ],
                );
              },
            ),
          ),
          Container(
            color: AppColors.background,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Grupo
                Container(
                  width: MediaQuery.of(context).size.width / 3 - 16,
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    grupo?.titulo ?? '', // <--- mostrar título o vacío
                    style: const TextStyle(
                      color: AppColors.accentColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Dificultad pills
                Container(
                  width: MediaQuery.of(context).size.width / 3 - 16,
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                  child: buildDificultadPills(widget.rutina.dificultad, 8, 16),
                ),
                // Repetición de fecha (puedes cambiarlo si es necesario)
                Container(
                  width: MediaQuery.of(context).size.width / 3 - 16,
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.centerRight,
                  child: Text(
                    fecha,
                    style: const TextStyle(
                      color: AppColors.accentColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.rutina.descripcion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.rutina.descripcion,
                  style: const TextStyle(
                    color: AppColors.accentColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // GRÁFICA de volumen por entrenamiento
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ChartWidget(
              title: 'Volumen por entrenamiento',
              labels: chartData.map((m) => m['inicio'] as String).toList(),
              values: chartData.map((m) => (m['volumen_total'] as num).toDouble()).toList(),
              textNoResults: 'No hay entrenamientos aún.',
            ),
          ),
        ],
      ),
    );
  }

  // función auxiliar para renderizar las “pills”
  TextStyle get _pillValueStyle => const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.background);
  Widget _buildPill(String title, Widget value, double width) {
    return Container(
      width: width,
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.mutedAdvertencia,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.background)),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = duration.inHours;
    final m = twoDigits(duration.inMinutes.remainder(60));
    final s = twoDigits(duration.inSeconds.remainder(60));
    return '$h:$m:$s';
  }
}
