import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/main.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/models/health/health.dart';
import 'package:mrfit/models/usuario/usuario.dart'; // Importa el modelo Usuario
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/utils/mr_functions.dart';
import 'package:mrfit/widgets/entrenamiento/entrenamiento_resumen_pastilla.dart';
import 'package:mrfit/widgets/chart/heart_grafica.dart';
import 'package:mrfit/widgets/entrenamiento/entrenamiento_realizado_mrfit.dart';
import 'package:logger/logger.dart';

/// Página que muestra siempre el resumen de salud en el rango [start, end]
/// y, si existe un entrenamiento creado en Mr Fit, lo añade debajo.
class EntrenamientoRealizadoPage extends ConsumerWidget {
  final dynamic idHealthConnect;
  final int id;
  final String title;
  final DateTime start;
  final DateTime end;
  final IconData icon;

  const EntrenamientoRealizadoPage({
    super.key,
    required this.idHealthConnect,
    this.id = 0,
    required this.title,
    required this.start,
    required this.end,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Usuario usuario = ref.watch(usuarioProvider);

    // Cargamos entrenamiento y datos de salud en paralelo.
    return FutureBuilder<_PageData>(
      future: _loadData(usuario),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _scaffoldConLoader('Cargando...');
        }
        if (snapshot.hasError) {
          Logger().e('Error al cargar datos en EntrenamientoRealizadoPage', error: snapshot.error, stackTrace: snapshot.stackTrace);
          return _scaffoldConError('Error al cargar los datos', snapshot.error);
        }

        final pageData = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              pageData.entrenamiento != null
                  ? MrFunctions.formatTimeAgo(
                      pageData.entrenamiento!.fin ?? pageData.entrenamiento!.inicio,
                    )
                  : MrFunctions.formatTimeAgo(end),
            ),
            actions: _menuActions(context, pageData.entrenamiento),
          ),
          body: Container(
            // Contenedor principal con bordes superiores redondeados, overflow oculto y margen horizontal
            decoration: const BoxDecoration(
              // color: AppColors.appBarBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            clipBehavior: Clip.hardEdge, // Oculta el overflow
            margin: const EdgeInsets.symmetric(horizontal: 20), // Margen horizontal de 20
            child: SingleChildScrollView(
              // Quitamos el padding horizontal, solo dejamos vertical si se desea
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila con el icono a la izquierda y la fecha a la derecha
                  Row(
                    children: [
                      // Columna para el icono
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.background, // Fondo del círculo
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.mutedAdvertencia, // Borde del círculo
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: 28,
                            color: AppColors.mutedAdvertencia,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Columna para la hora alineada a la izquierda
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.textNormal, // Color definido para texto medio
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${TimeOfDay.fromDateTime(start).format(context)} - ${TimeOfDay.fromDateTime(end).format(context)}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: AppColors.textMedium, // Color definido para texto medio
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ResumenPastilla(
                    entrenamiento: pageData.entrenamiento,
                    steps: usuario.isHealthConnectAvailable ? pageData.healthSummary?['STEPS']?['sum'] : 0,
                    distance: usuario.isHealthConnectAvailable ? pageData.healthSummary?['DISTANCE_DELTA']?['sum'] : 0,
                    heartRateAvg: usuario.isHealthConnectAvailable ? (pageData.healthSummary?['HEART_RATE']?['avg'] != null ? (pageData.healthSummary?['HEART_RATE']?['avg'] as num).toInt() : null) : 0,
                  ),
                  const SizedBox(height: 20),
                  // Solo mostramos el resumen de salud si Health Connect está disponible
                  if (usuario.isHealthConnectAvailable) ...[
                    ResumenSaludEntrenamiento(
                      datosSalud: pageData.healthSummary,
                      start: start,
                      end: end,
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Solo si existe un entrenamiento Mr Fit.
                  if (pageData.entrenamiento != null)
                    EntrenamientoMrFitWidget(
                      entrenamiento: pageData.entrenamiento!,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_PageData> _loadData(Usuario usuario) async {
    Entrenamiento? entrenamiento;
    Map<String, dynamic>? healthSummary;
    if (usuario.isHealthConnectAvailable) {
      entrenamiento = await Entrenamiento.loadByUuid(idHealthConnect).catchError((_) => null);

      healthSummary = await HealthSummary(usuario).getSummaryByDateRange(start, end).catchError((_) => <String, dynamic>{});
    } else {
      entrenamiento = await Entrenamiento.loadById(id).catchError((_) => null);
    }
    return _PageData(entrenamiento: entrenamiento, healthSummary: healthSummary);
  }

  // Helpers UI
  List<Widget> _menuActions(BuildContext context, Entrenamiento? ent) {
    if (ent == null) return [];
    return [
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) async {
          if (value == 'Borrar') {
            await ent.delete();
            // Volvemos al inicio usando Navigator
            Navigator.pushAndRemoveUntil(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(builder: (_) => const MyApp()),
              (route) => false,
            );
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'Borrar', child: Text('Borrar')),
        ],
      ),
    ];
  }

  Scaffold _scaffoldConLoader(String titulo) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Scaffold _scaffoldConError(String titulo, Object? error) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.mutedRed, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Algo fue mal',
              style: TextStyle(fontSize: 18, color: AppColors.mutedAdvertencia),
            ),
            Text('$error', style: const TextStyle(color: AppColors.mutedRed)),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final Entrenamiento? entrenamiento;
  final Map<String, dynamic>? healthSummary;

  _PageData({required this.entrenamiento, required this.healthSummary});
}

/// Muestra siempre los 3 datos de salud (o placeholder si no hay).
class ResumenSaludEntrenamiento extends StatelessWidget {
  final Map<String, dynamic>? datosSalud;
  final DateTime? start;
  final DateTime? end;

  const ResumenSaludEntrenamiento({
    super.key,
    required this.datosSalud,
    this.start,
    this.end,
  });

  @override
  Widget build(BuildContext context) {
    if (datosSalud == null) {
      return const _PlaceholderSalud('No disponible');
    }

    final heartRateData = datosSalud!['HEART_RATE'] as Map?;
    final heartRateDataPoints = heartRateData?['dataPoints'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gráfica de frecuencia cardiaca si hay datos
        if (heartRateDataPoints.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: HeartGrafica(
              dataPoints: heartRateDataPoints,
              granularity: "second",
              startDate: start,
              endDate: end,
            ),
          ),
        // Los pasos y la distancia ahora se muestran en la pastilla, no aquí.
      ],
    );
  }
}

class _PlaceholderSalud extends StatelessWidget {
  final String texto;
  const _PlaceholderSalud(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      'Resumen de salud: $texto',
      style: const TextStyle(color: AppColors.mutedAdvertencia),
    );
  }
}
