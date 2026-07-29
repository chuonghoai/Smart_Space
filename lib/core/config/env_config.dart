class EnvConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const int apiTimeout = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 10000,
  );
}
