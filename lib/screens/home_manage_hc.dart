import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/main.dart';
import 'package:mrfit/models/usuario/usuario.dart';

class HomeManageHCWidget extends StatelessWidget {
  final VoidCallback onInstallHealthConnect;
  final Usuario usuario;

  const HomeManageHCWidget({
    Key? key,
    required this.onInstallHealthConnect,
    required this.usuario,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.mutedAdvertencia,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                IconButton(
                  icon: const Icon(Icons.info_outline, color: AppColors.background),
                  onPressed: () => _showInfoDialog(context),
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
              'Necesario para acceder a todas las funcionalidades y otorgar los permisos necesarios.',
              style: TextStyle(fontSize: 14, color: AppColors.background),
            ),
            const SizedBox(height: 4),
            const Text(
              'No te preocupes por la privacidad, nunca saldrán los datos de tu dispositivo.',
              style: TextStyle(fontSize: 14, color: AppColors.background),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.background,
                    ),
                    onPressed: () async {
                      final isAvailable = await usuario.isHealthConnectAvailable();
                      if (isAvailable) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const MyApp()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Health Connect no está disponible. Por favor, instálalo para continuar.',
                              style: TextStyle(color: AppColors.textNormal),
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
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentColor),
                    child: const Text('Instalar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
}
