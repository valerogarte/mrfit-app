import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/widgets/chart/grafica.dart';
import 'package:mrfit/screens/ejercicios/detalle/ejercicio_detalle.dart';
import 'package:mrfit/widgets/animated_image.dart';

class DetalleMusculoInformacion extends StatefulWidget {
  final String musculo;
  final List<Entrenamiento> entrenamientos;

  const DetalleMusculoInformacion({
    super.key,
    required this.musculo,
    required this.entrenamientos,
  });

  @override
  State<DetalleMusculoInformacion> createState() => _DetalleMusculoInformacionState();
}

class _DetalleMusculoInformacionState extends State<DetalleMusculoInformacion> {
  List<Map<String, dynamic>> _volumenes = [];
  List<Ejercicio> _ejerciciosPrincipalesMasUsados = [];
  List<Ejercicio> _ejerciciosSecundariosMasUsados = []; // Nueva lista para secundarios
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMusculoYVolumenes();
  }

  // Carga el músculo por nombre, sus volúmenes máximos y los ejercicios más usados
  Future<void> _loadMusculoYVolumenes() async {
    setState(() => _loading = true);
    final musculo = await Musculo.getByName(widget.musculo);
    if (musculo != null) {
      final volumenes = await musculo.getVolumenesMaximos();
      final ejerciciosPrincipalesMasUsados = await musculo.getEjerciciosPrincipalMasUsados();
      final ejerciciosSecundariosMasUsados = await musculo.getEjerciciosSecundarioMasUsados();
      setState(() {
        _volumenes = volumenes;
        _ejerciciosPrincipalesMasUsados = ejerciciosPrincipalesMasUsados;
        _ejerciciosSecundariosMasUsados = ejerciciosSecundariosMasUsados;
        _loading = false;
      });
    } else {
      setState(() {
        _volumenes = [];
        _ejerciciosPrincipalesMasUsados = [];
        _ejerciciosSecundariosMasUsados = [];
        _loading = false;
      });
    }
  }

  // Prepara los datos y utiliza ChartWidget para mostrar la evolución del volumen máximo
  Widget buildVolumenesChart() {
    if (_volumenes.isEmpty) {
      return Text(
        "No hay registros de volumen máximo.",
        style: TextStyle(color: AppColors.textMedium),
      );
    }

    // Extrae fechas y volúmenes para el gráfico reutilizable
    final labels = _volumenes.map((v) => v['fecha']?.toString().substring(0, 10) ?? '').toList();
    final values = _volumenes.map((v) => (v['volumen'] as num?)?.toDouble() ?? 0.0).toList();

    return ChartWidget(
      labels: labels,
      values: values,
      textNoResults: "No hay registros de volumen máximo.",
    );
  }

  // Función para generar una sección con título y contenido
  Widget buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.accentColor,
          ),
        ),
        const SizedBox(height: 5),
        content,
        const SizedBox(height: 20),
      ],
    );
  }

  // Sección de anatomía. Si es pecho, muestra sus subdivisiones
  Widget buildAnatomiaSection() {
    if (widget.musculo.toLowerCase() == 'pecho') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSection(
            "Pecho Superior",
            Text(
              "Descripción y función del pecho superior.",
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
          buildSection(
            "Pecho Medio",
            Text(
              "Descripción y función del pecho medio.",
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
          buildSection(
            "Pecho Inferior",
            Text(
              "Descripción y función del pecho inferior.",
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
        ],
      );
    } else {
      return buildSection(
        "Anatomía",
        Text(
          "Descripción anatómica general del músculo.",
          style: TextStyle(color: AppColors.textMedium),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // Muestra un indicador de carga mientras se obtienen los datos
      return Center(child: CircularProgressIndicator());
    }
    // SafeArea externo, margen fuera del contenedor principal, solo esquinas superiores redondeadas
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la ficha técnica
              Text(
                'Ficha Técnica:',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 20),
              // Sección Anatomía
              // buildAnatomiaSection(),
              // Sección Volúmenes máximos (gráfico)
              buildSection(
                "Evolución MrPoints",
                buildVolumenesChart(),
              ),
              // Sección Ejercicios principales
              buildSection(
                "Ejercicios más usados como principal",
                _ejerciciosPrincipalesMasUsados.isEmpty
                    ? Text(
                        "No hay ejercicios registrados.",
                        style: TextStyle(color: AppColors.textMedium),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        height: 70,
                        alignment: Alignment.center,
                        clipBehavior: Clip.hardEdge,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _ejerciciosPrincipalesMasUsados.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final ejercicio = _ejerciciosPrincipalesMasUsados[index];
                            return GestureDetector(
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EjercicioDetallePage(
                                      ejercicio: ejercicio,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: AnimatedImage(
                                  ejercicio: ejercicio,
                                  width: 105,
                                  height: 70,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              // Nueva sección: Ejercicios secundarios
              buildSection(
                "Ejercicios más usados como secundario",
                _ejerciciosSecundariosMasUsados.isEmpty
                    ? Text(
                        "No hay ejercicios registrados.",
                        style: TextStyle(color: AppColors.textMedium),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        height: 70,
                        alignment: Alignment.center,
                        clipBehavior: Clip.hardEdge,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _ejerciciosSecundariosMasUsados.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final ejercicio = _ejerciciosSecundariosMasUsados[index];
                            return GestureDetector(
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EjercicioDetallePage(
                                      ejercicio: ejercicio,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: AnimatedImage(
                                  ejercicio: ejercicio,
                                  width: 105,
                                  height: 70,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              // Sección Consejos
              // buildSection(
              //   "Consejos",
              //   Text(
              //     "Recomendaciones para mejorar la técnica y optimizar el entrenamiento.",
              //     style: TextStyle(color: AppColors.textMedium),
              //   ),
              // ),
              // Sección Prevención de Lesiones
              // buildSection(
              //   "Prevención de Lesiones",
              //   Text(
              //     "Sugerencias para evitar sobrecargas y cuidar la salud muscular.",
              //     style: TextStyle(color: AppColors.textMedium),
              //   ),
              // ),
              // Sección Recursos
              // buildSection(
              //   "Recursos",
              //   Text(
              //     "Enlaces y lecturas adicionales para profundizar en el tema.",
              //     style: TextStyle(color: AppColors.textMedium),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
