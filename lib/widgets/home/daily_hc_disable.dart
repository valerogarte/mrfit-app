import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/models/cache/custom_cache.dart';

/// Widget funcional para mostrar el aviso de Health Connect no instalado.
/// Permite ser insertado fácilmente como bloque en otras pantallas.
/// Se sigue el patrón de dailyHearthWidget para consistencia.
Widget dailyHCDisableWidget({
  required Usuario usuario,
  required VoidCallback onInstallHealthConnect,
  required VoidCallback onClose,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.mutedAdvertencia,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/rrss/hc.png',
              width: 50,
              height: 50,
            ),
            Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.info_outline, color: AppColors.background),
                    onPressed: () => _showInfoDialog(context),
                    tooltip: 'Información sobre Health Connect',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.background),
                  tooltip: 'Cerrar aviso',
                  onPressed: () async {
                    await CustomCache.set("warning_hc_disable", "0");
                    onClose();
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Health Connect no está instalado',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.background,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Necesario para acceder a todas las funcionalidades. Otorga todos los permisos necesarios.',
          style: TextStyle(fontSize: 14, color: AppColors.background),
        ),
        const SizedBox(height: 4),
        const Text(
          'No te preocupes por la privacidad, nunca saldrán los datos de tu dispositivo.',
          style: TextStyle(fontSize: 14, color: AppColors.background),
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (context) => Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.background,
                  ),
                  onPressed: () async {
                    // Verifica si Health Connect está disponible antes de continuar
                    final isAvailable = await usuario.isHealthConnectAvailableUser();
                    if (isAvailable) {
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pushReplacementNamed('/');
                    } else {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Health Connect no está disponible. Por favor, instálalo para continuar.',
                            style: TextStyle(color: AppColors.background),
                          ),
                          backgroundColor: AppColors.mutedAdvertencia,
                        ),
                      );
                    }
                  },
                  child: const Text('Lo tengo!', style: TextStyle(color: AppColors.textNormal)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onInstallHealthConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text('Instalar'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Muestra un diálogo informativo sobre Health Connect.
/// Se mantiene privado para uso interno del widget.
void _showInfoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: const Text('¿Qué es Health Connect?', style: TextStyle(color: AppColors.textNormal)),
      content: const Text(
        'Health Connect es una plataforma que permite a las aplicaciones de salud y fitness '
        'compartir datos de manera segura en tu dispositivo. Garantiza la privacidad y seguridad de tus datos.',
        style: TextStyle(color: AppColors.textMedium),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cerrar', style: TextStyle(color: AppColors.accentColor)),
        ),
      ],
    ),
  );
}
