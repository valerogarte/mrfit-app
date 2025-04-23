import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';

class DetalleMusculoInformacion extends StatelessWidget {
  final String musculo;
  final List<Entrenamiento> entrenamientos;
  const DetalleMusculoInformacion({
    Key? key,
    required this.musculo,
    required this.entrenamientos,
  }) : super(key: key);

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
    if (musculo.toLowerCase() == 'pecho') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSection(
            "Pecho Superior",
            Text(
              "Descripción y función del pecho superior.",
              style: TextStyle(color: AppColors.textColor),
            ),
          ),
          buildSection(
            "Pecho Medio",
            Text(
              "Descripción y función del pecho medio.",
              style: TextStyle(color: AppColors.textColor),
            ),
          ),
          buildSection(
            "Pecho Inferior",
            Text(
              "Descripción y función del pecho inferior.",
              style: TextStyle(color: AppColors.textColor),
            ),
          ),
        ],
      );
    } else {
      return buildSection(
        "Anatomía",
        Text(
          "Descripción anatómica general del músculo.",
          style: TextStyle(color: AppColors.textColor),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la ficha técnica
            Text(
              'Ficha Técnica: $musculo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 20),
            // Sección Anatomía
            buildAnatomiaSection(),
            // Sección Ejercicios
            buildSection(
              "Ejercicios más usados",
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entrenamientos
                    .map((ent) => Text(
                          "- Entrenamiento",
                          style: TextStyle(color: AppColors.textColor),
                        ))
                    .toList(),
              ),
            ),
            // Sección Consejos
            buildSection(
              "Consejos",
              Text(
                "Recomendaciones para mejorar la técnica y optimizar el entrenamiento.",
                style: TextStyle(color: AppColors.textColor),
              ),
            ),
            // Sección Prevención de Lesiones
            buildSection(
              "Prevención de Lesiones",
              Text(
                "Sugerencias para evitar sobrecargas y cuidar la salud muscular.",
                style: TextStyle(color: AppColors.textColor),
              ),
            ),
            // Sección Recursos
            buildSection(
              "Recursos",
              Text(
                "Enlaces y lecturas adicionales para profundizar en el tema.",
                style: TextStyle(color: AppColors.textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
