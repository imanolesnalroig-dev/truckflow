class AppConfig {
  static const String apiBaseUrl = 'https://truckflow-api-794599390333.europe-west1.run.app';
  static const String apiVersion = 'v1';

  static String get apiUrl => '$apiBaseUrl/api/$apiVersion';

  // Mapbox - user should add their own token
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Cache settings
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration cacheMaxAge = Duration(hours: 1);
}
