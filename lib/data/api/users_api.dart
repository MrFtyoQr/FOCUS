import 'api_client.dart';
import 'auth_api.dart';

/// Endpoints de usuarios (blueprint):
/// - GET /api/v1/users?skip=0&limit=100 (solo SUPER_ADMIN)
class UsersApi {
  UsersApi._();
  static final UsersApi _instance = UsersApi._();
  factory UsersApi() => _instance;

  final ApiClient _client = ApiClient();

  Future<List<UserResponse>> getUsers({int skip = 0, int limit = 100}) async {
    final response = await _client.dio.get<List<dynamic>>(
      'users',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map>()
        .map((e) => UserResponse.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

