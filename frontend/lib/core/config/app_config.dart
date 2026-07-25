/// Central runtime configuration.
///
/// Override the API base URL at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  static const String storeName = String.fromEnvironment(
    'STORE_NAME',
    defaultValue: 'My Store',
  );
}
