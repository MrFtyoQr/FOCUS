import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();
  static final SecureStorage instance = SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessTokenKey  = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _pinKey           = 'user_pin';

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _accessTokenKey,  value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  Future<String?> getAccessToken()  async => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() async => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> savePin(String pin) async => _storage.write(key: _pinKey, value: pin);
  Future<String?> getPin()           async => _storage.read(key: _pinKey);
  Future<bool>    hasPin()           async => (await getPin()) != null;
  Future<void>    clearPin()         async => _storage.delete(key: _pinKey);

  Future<bool> hasSession() async => (await getAccessToken()) != null;
  Future<void> clearAll()   async => _storage.deleteAll();
}
