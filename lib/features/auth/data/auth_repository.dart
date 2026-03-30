import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user.dart';

class AuthRepository {
  final _api = ApiClient.instance;

  Future<UserModel> login({required String email, required String password}) async {
    final res = await _api.post(ApiEndpoints.login, data: {'email': email, 'password': password});
    await SecureStorage.instance.saveTokens(access: res.data['access'] as String, refresh: res.data['refresh'] as String);
    return getMe();
  }

  Future<UserModel> register({required String email, required String firstName, required String lastName, required String password}) async {
    final res = await _api.post('/auth/register/', data: {
      'email': email, 'first_name': firstName, 'last_name': lastName, 'password': password,
    });
    await SecureStorage.instance.saveTokens(access: res.data['access'] as String, refresh: res.data['refresh'] as String);
    return getMe();
  }

  Future<UserModel> acceptInvitation({required String token, required String firstName, required String lastName, required String password}) async {
    final res = await _api.post(ApiEndpoints.inviteAccept, data: {'token': token, 'first_name': firstName, 'last_name': lastName, 'password': password});
    await SecureStorage.instance.saveTokens(access: res.data['access'] as String, refresh: res.data['refresh'] as String);
    return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> getMe() async {
    final res = await _api.get(ApiEndpoints.me);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      final refresh = await SecureStorage.instance.getRefreshToken();
      if (refresh != null) await _api.post(ApiEndpoints.logout, data: {'refresh': refresh});
    } catch (_) {
    } finally {
      await SecureStorage.instance.clearAll();
    }
  }

  Future<Map<String, dynamic>> validateInviteToken(String token) async {
    final res = await _api.get(ApiEndpoints.inviteValidate(token));
    return res.data as Map<String, dynamic>;
  }
}
