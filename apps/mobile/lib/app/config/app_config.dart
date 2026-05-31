/// Build-time configuration.
///
/// The API base URL is injected with `--dart-define` so the same build can
/// point at a local server during development and at the hosted (Oracle)
/// deployment in production. Default is the local FastAPI dev server.
///
/// Example:
///   flutter run --dart-define=RECONSNAP_API_BASE_URL=http://10.0.2.2:8000
///
/// Note: Android emulators reach the host machine via 10.0.2.2, not localhost.
class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'RECONSNAP_API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
