part of 'usuario.dart';

extension UsuarioActivityRecognitionExtension on Usuario {
  Future<void> ensurePermissions() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt >= 29) {
        // En Android 10+ (API 29+) sí hace falta pedir permiso en runtime
        if (await Permission.activityRecognition.isDenied) {
          await Permission.activityRecognition.request();
        }
      }
    }
  }

  /// Consulta si Activity Recognition está disponible y lo setea en el usuario.
  Future<bool> isActivityRecognitionAvailableUser() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt < 29) {
        // En versiones < 29 asumimos que el permiso está concedido (implícito)
        return setActivityRecognition(true);
      }
    }
    final status = await Permission.activityRecognition.status;

    return setActivityRecognition(status.isGranted);
  }

  /// Solicita el permiso de Activity Recognition al usuario y retorna si fue concedido.
  Future<bool> requestActivityRecognitionPermission() async {
    // Solicita el permiso y, si fue concedido, actualiza el estado en el usuario.
    final status = await Permission.activityRecognition.request();
    if (status == PermissionStatus.granted) {
      setActivityRecognition(true);
      return true;
    }
    return false;
  }
}
