class MrFunctions {
  static String formatTimeAgo(DateTime tiempo) {
    final now = DateTime.now();
    final difference = now.difference(tiempo);
    final years = (difference.inDays / 365).floor();
    final months = (difference.inDays / 30).floor();
    final days = difference.inDays;
    final hours = difference.inHours;
    if (years > 0) {
      return 'Hace $years ${years == 1 ? 'año' : 'años'}';
    } else if (months > 0) {
      return 'Hace $months ${months == 1 ? 'mes' : 'meses'}';
    } else if (days > 1) {
      return 'Hace $days días';
    } else if (days == 0 || (now.day != tiempo.day && hours < 24)) {
      return 'Ayer';
    } else if (hours >= 24 && hours < 48 && days == 1) {
      return 'Anteayer';
    } else if (hours < 1) {
      return 'Recientemente';
    } else {
      return 'Hace $hours ${hours == 1 ? 'hora' : 'horas'}';
    }
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      String hours = twoDigits(duration.inHours);
      return "$hours:$minutes:$seconds";
    } else {
      return "$minutes:$seconds";
    }
  }

  /// Convierte una versión en formato 'x.y.z' a un entero.
  static int versionToInt(String version) {
    final parts = version.split('.');
    if (parts.length < 2) return 0;

    int major = int.tryParse(parts[0]) ?? 0;
    int minor = int.tryParse(parts[1]) ?? 0;
    int patch = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

    major = major * 1000000;
    minor = minor * 1000;

    return major + minor + patch;
  }
}
