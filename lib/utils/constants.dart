class AppConstants {
  static const String version = '1.0.27';

  static const String hostImages = 'https://mrfit.es/MrFit/media/';

  static const String appName = 'MrFit';

  static const String domainNameApp = 'es.mrfit.app';

  // Quiero montar una lista de prioridad de la aplicación para pintar los datos de health
  static const List<String> healthPriority = [
    domainNameApp,
    'com.google.android.apps.fitness',
    'com.mobvoi.companion.at',
  ];
}
