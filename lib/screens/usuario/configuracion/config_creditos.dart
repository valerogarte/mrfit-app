import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class ConfiguracionCreditosPage extends StatelessWidget {
  final String opcion;
  const ConfiguracionCreditosPage({super.key, required this.opcion});

  @override
  Widget build(BuildContext context) {
    String title;
    String description;
    IconData icon;

    switch (opcion) {
      case 'Mejoras en la app':
        title = 'Mejoras en la app';
        description = 'Si deseas proponer mejoras, por favor abre un issue en nuestro repositorio de GitHub:\n\n'
            'https://github.com/valerogarte/mr-fit\n\n'
            'Cada sugerencia es como una semilla que ayuda a crecer y evolucionar la aplicación, dándole un nuevo aire y vitalidad.';
        icon = Icons.build;
        break;
      case 'OpenSource':
        title = 'OpenSource';
        description = 'He decidido hacer este proyecto open source porque creo en el poder de la colaboración y la transparencia. '
            'Compartir el código invita a la comunidad a participar, detectar errores y proponer mejoras. '
            'Esta apertura es un homenaje a la creatividad colectiva, una invitación a soñar y construir juntos un futuro mejor.\n\n'
            'Los datos generados por esta aplicación nunca saldrán de esta aplicación. Puedes generar backups propios para que tú seas el propietario de los mismos. '
            'Desde MrFit nos lo tomamos muy en serio.';
        icon = Icons.code;
        break;
      case 'Daniel Valero González':
        title = 'Acerca del desarrollador';
        description = 'Soy Daniel Valero González, desarrollador de la app. Soy un apasionado del Open Source, la inteligencia artificial y la pintura. '
            'Siempre busco nuevos retos y colaboraciones, y pongo mi pasión en cada línea de código.';
        icon = Icons.person;
        break;
      default:
        title = '';
        description = '';
        icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mantenemos este título y eliminamos el duplicado que aparece en otra parte de la app.
              Row(
                children: [
                  Icon(icon, color: AppColors.accentColor, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(fontSize: 16, color: AppColors.background),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
