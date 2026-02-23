import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

/// Almacenamiento seguro para tokens, device_fingerprint y datos mínimos del usuario.
/// No usar SharedPreferences para datos sensibles.
class SecureStorage {
  SecureStorage._();
  static final SecureStorage _instance = SecureStorage._();
  factory SecureStorage() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> getAccessToken() => _storage.read(key: AppConstants.keyAccessToken);
  Future<void> setAccessToken(String value) => _storage.write(key: AppConstants.keyAccessToken, value: value);

  Future<String?> getRefreshToken() => _storage.read(key: AppConstants.keyRefreshToken);
  Future<void> setRefreshToken(String? value) {
    if (value == null || value.isEmpty) return _storage.delete(key: AppConstants.keyRefreshToken);
    return _storage.write(key: AppConstants.keyRefreshToken, value: value);
  }

  Future<String?> getDeviceFingerprint() => _storage.read(key: AppConstants.keyDeviceFingerprint);
  Future<void> setDeviceFingerprint(String value) => _storage.write(key: AppConstants.keyDeviceFingerprint, value: value);

  Future<String?> getUserId() => _storage.read(key: AppConstants.keyUserId);
  Future<String?> getUserEmail() => _storage.read(key: AppConstants.keyUserEmail);
  Future<String?> getUserName() => _storage.read(key: AppConstants.keyUserName);
  Future<String?> getUserRol() => _storage.read(key: AppConstants.keyUserRol);

  Future<void> setUserMinimal({
    required String userId,
    required String email,
    String? name,
    String? rol,
  }) async {
    await _storage.write(key: AppConstants.keyUserId, value: userId);
    await _storage.write(key: AppConstants.keyUserEmail, value: email);
    await _storage.write(key: AppConstants.keyUserName, value: name ?? '');
    await _storage.write(key: AppConstants.keyUserRol, value: rol ?? '');
  }

  Future<bool> getRequiresUnlock() async {
    final v = await _storage.read(key: AppConstants.keyRequiresUnlock);
    return v == 'true';
  }

  Future<void> setRequiresUnlock(bool value) =>
      _storage.write(key: AppConstants.keyRequiresUnlock, value: value.toString());

  /// Devuelve true si hay un access_token guardado (sesión existente).
  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Limpiar toda la sesión (logout).
  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
    await _storage.delete(key: AppConstants.keyUserId);
    await _storage.delete(key: AppConstants.keyUserEmail);
    await _storage.delete(key: AppConstants.keyUserName);
    await _storage.delete(key: AppConstants.keyUserRol);
    await _storage.delete(key: AppConstants.keyRequiresUnlock);
    // No borrar device_fingerprint para reutilizarlo en próximo login
  }
}
