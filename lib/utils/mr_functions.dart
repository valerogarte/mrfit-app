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
    } else if (days == 1 || (now.day != tiempo.day && hours < 24)) {
      return 'Ayer';
    } else if (hours < 1) {
      return 'Recientemente';
    } else {
      return 'Hace $hours ${hours == 1 ? 'hora' : 'horas'}';
    }
  }
}
