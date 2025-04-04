import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class ConfiguracionCreditosPage extends StatelessWidget {
  final String opcion;
  const ConfiguracionCreditosPage({super.key, required this.opcion});

  @override
  Widget build(BuildContext context) {
    String title;
    String description;

    switch (opcion) {
      case 'Mejoras en la app':
        title = 'Mejoras en la app';
        description = 'Si deseas proponer mejoras, por favor abre un issue en nuestro repositorio de GitHub:\n\n'
            'https://github.com/valerogarte/vagfit-app\n\n'
            'Tu contribución es muy importante para seguir perfeccionando la aplicación.';
        break;
      case 'OpenSource':
        title = 'OpenSource';
        description = 'La aplicación es open source, lo que implica que su código fuente es público y cualquiera puede revisarlo, '
            'modificarlo o contribuir a su desarrollo. Esto fomenta la transparencia, la colaboración y la innovación.';
        break;
      case 'Daniel Valero González':
        title = 'Acerca del desarrollador';
        description = 'Daniel Valero González es el desarrollador principal de la app. Con amplia experiencia en CMS (WordPress y Drupal) '
            'y un gran interés por la inteligencia artificial y la cosmología, trabaja para crear aplicaciones de alta calidad. '
            'Siempre abierto a nuevos retos y colaboraciones, se esfuerza por aportar valor a la comunidad.';
        break;
      default:
        title = '';
        description = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.whiteText)),
        const SizedBox(height: 10),
        Text(description, style: const TextStyle(fontSize: 16, color: AppColors.textColor)),
      ],
    );
  }
}
