import 'package:flutter/foundation.dart';
import '../api/auth_api.dart';
import '../../core/security/secure_storage.dart';
import '../../core/security/device_fingerprint.dart';

/// Repositorio de autenticación: orquesta API y almacenamiento seguro.
class AuthRepository {
  AuthRepository._();
  static final AuthRepository _instance = AuthRepository._();
  factory AuthRepository() => _instance;

  final AuthApi _api = AuthApi();
  final SecureStorage _storage = SecureStorage();
  final DeviceFingerprint _fingerprint = DeviceFingerprint();

  /// Login: envía device_fingerprint, guarda token y usuario mínimo, marca requires_unlock.
  Future<void> login(String email, String password) async {
    final deviceFingerprint = await _fingerprint.getOrCreateFingerprint();
    final response = await _api.login(
      email: email,
      password: password,
      deviceFingerprint: deviceFingerprint,
    );
    await _storage.setAccessToken(response.accessToken);
    if (response.refreshToken != null && response.refreshToken!.isNotEmpty) {
      await _storage.setRefreshToken(response.refreshToken);
    }
    await _storage.setUserMinimal(
      userId: response.user.id.toString(),
      email: response.user.email,
      name: response.user.displayName,
      rol: response.user.rol,
    );
    await _storage.setRequiresUnlock(true);
  }

  /// Registro: solo llama al API; tras éxito el usuario debe ir a login.
  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    String? apellido,
  }) async {
    // [REG_DEBUG] TODO: retirar cuando se localice el retraso
    final sw = Stopwatch()..start();
    debugPrint('[REG_DEBUG] AuthRepository.register: llamando API...');
    await _api.register(email: email, password: password, nombre: nombre, apellido: apellido);
    sw.stop();
    debugPrint('[REG_DEBUG] AuthRepository.register: completado en ${sw.elapsedMilliseconds}ms');
  }

  /// Cerrar sesión: llamar backend y limpiar local.
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _storage.clearSession();
  }

  /// Refresca usuario actual desde GET /users/me y actualiza SecureStorage (incl. rol).
  /// Útil para que cambios de rol en BD se reflejen sin cerrar sesión.
  Future<void> refreshUserFromBackend() async {
    final user = await _api.getMe();
    await _storage.setUserMinimal(
      userId: user.id.toString(),
      email: user.email,
      name: user.displayName,
      rol: user.rol,
    );
  }

  /// True si hay sesión guardada.
  Future<bool> hasSession() => _storage.hasSession();

  /// Marcar que ya se pasó la pantalla de desbloqueo (biometría/PIN).
  Future<void> clearRequiresUnlock() => _storage.setRequiresUnlock(false);
}
