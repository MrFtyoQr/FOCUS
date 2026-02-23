import '../core/security/secure_storage.dart';
import '../core/security/local_auth.dart';
import '../data/repositories/auth_repository.dart';

/// Servicio de autenticación: login, logout, registro, estado de desbloqueo.
/// La UI llama a este servicio; no a repositorios ni API directamente.
class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final AuthRepository _repo = AuthRepository();
  final SecureStorage _storage = SecureStorage();
  final LocalAuth _localAuth = LocalAuth();

  /// Iniciar sesión con email y contraseña.
  /// Guarda token y usuario; activa pantalla de desbloqueo en la siguiente apertura.
  Future<void> login(String email, String password) async {
    await _repo.login(email, password);
  }

  /// Cerrar sesión (backend + limpiar local).
  Future<void> logout() async {
    await _repo.logout();
  }

  /// Registro de usuario.
  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    String? apellido,
  }) async {
    await _repo.register(email: email, password: password, nombre: nombre, apellido: apellido);
  }

  /// ¿Hay token guardado? (sesión existente)
  Future<bool> hasSession() => _repo.hasSession();

  /// ¿Hay que mostrar pantalla de desbloqueo (biometría/PIN)?
  Future<bool> requiresUnlock() => _storage.getRequiresUnlock();

  /// Desbloquear: autenticación local (biometría o PIN).
  /// Devuelve true si el usuario se autenticó.
  Future<bool> unlockWithBiometrics() => _localAuth.authenticate();

  /// ¿El dispositivo tiene biometría disponible?
  Future<bool> hasBiometricsAvailable() => _localAuth.hasBiometricsAvailable();

  /// Tras desbloquear correctamente, marcar que no hace falta desbloqueo hasta la próxima apertura.
  Future<void> markUnlocked() => _repo.clearRequiresUnlock();
}
