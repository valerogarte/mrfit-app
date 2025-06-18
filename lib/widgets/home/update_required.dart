import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/utils/constants.dart';
import 'package:mrfit/utils/mr_functions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Verifica si la versión de la app cumple con el mínimo requerido desde Remote Config.
Future<bool> checkMinVersionCode() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(hours: 12),
  ));
  await remoteConfig.fetchAndActivate();

  final minVersionCodeStr = remoteConfig.getString('min_version_code').isNotEmpty ? remoteConfig.getString('min_version_code') : '1.0.1';
  final minVersionCode = MrFunctions.versionToInt(minVersionCodeStr);

  final currentVersionCode = MrFunctions.versionToInt(AppConstants.version);

  if (currentVersionCode < minVersionCode) {
    runApp(
      MaterialApp(
        theme: buildDialogTheme(),
        home: const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: UpdateRequiredDialog(),
          ),
        ),
      ),
    );
    return false;
  }
  return true;
}

/// Devuelve un ThemeData consistente con la app para el diálogo de actualización.
ThemeData buildDialogTheme() => ThemeData(
      primaryColor: AppColors.accentColor,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'MadeTommy',
      dialogBackgroundColor: AppColors.cardBackground,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.textNormal, fontFamily: 'MadeTommy'),
        bodyMedium: TextStyle(color: AppColors.textMedium, fontFamily: 'MadeTommy'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentColor,
          foregroundColor: AppColors.textNormal,
        ),
      ),
    );

/// Widget reutilizable para mostrar el mensaje de actualización requerida.
/// Utiliza la estética, tipografía y colores definidos por la app.
class UpdateRequiredDialog extends StatelessWidget {
  const UpdateRequiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentColor.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.system_update, color: AppColors.mutedAdvertencia, size: 48),
              const SizedBox(height: 16),
              Text(
                'Actualización requerida',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: AppColors.mutedAdvertencia,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Por favor, actualiza la app para continuar.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: AppColors.textNormal,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Abre la Play Store para actualizar la app.
                    const url = 'https://play.google.com/store/apps/details?id=com.tuempresa.tuapp'; // Reemplaza con tu package name real
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    foregroundColor: AppColors.textNormal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Actualizar',
                    style: TextStyle(
                      fontFamily: 'MadeTommy',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
