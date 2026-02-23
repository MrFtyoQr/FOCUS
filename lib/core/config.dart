/// Configuración de la aplicación: URL base del API, timeouts.
/// Evitar URLs en claro en producción; usar variables de entorno o flavors.
class AppConfig {
  AppConfig._();

  /// URL base del API. Debe terminar en / para que Dio resuelva bien paths relativos (ej. auth/login → .../api/v1/auth/login).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.16.18.202:8000/api/v1/',
  );

  /// Timeout para peticiones HTTP (conexión y lectura).
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Timeout de inactividad antes de pedir desbloqueo (biometría/PIN).
  static const Duration inactivityTimeout = Duration(minutes: 5);
}
