import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user.dart';

class AuthRepository {
  final _api = ApiClient.instance;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    await SecureStorage.instance.saveTokens(
      access:  response.data['access']  as String,
      refresh: response.data['refresh'] as String,
    );
    return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> acceptInvitation({
    required String token,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final response = await _api.post(ApiEndpoints.acceptInvite, data: {
      'token':      token,
      'email':      email,
      'first_name': firstName,
      'last_name':  lastName,
      'password':   password,
    });
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> getMe() async {
    final response = await _api.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      final refresh = await SecureStorage.instance.getRefreshToken();
      if (refresh != null) {
        await _api.post(ApiEndpoints.logout, data: {'refresh': refresh});
      }
    } catch (_) {
      // Si falla el logout en servidor, limpiamos local igualmente
    } finally {
      await SecureStorage.instance.clearAll();
    }
  }

  Future<void> enableBiometric(String deviceId) async {
    await _api.post(ApiEndpoints.biometricEnable, data: {'device_id': deviceId});
  }

  Future<void> disableBiometric() async {
    await _api.post(ApiEndpoints.biometricDisable);
  }

  Future<UserModel> biometricLogin({
    required String deviceId,
    required String refresh,
  }) async {
    final response = await _api.post(ApiEndpoints.biometricLogin, data: {
      'device_id': deviceId,
      'refresh':   refresh,
    });
    await SecureStorage.instance.saveTokens(
      access:  response.data['access']  as String,
      refresh: response.data['refresh'] as String,
    );
    return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<void> completeOnboarding() async {
    await _api.post(ApiEndpoints.onboardingComplete);
  }
}
