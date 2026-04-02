import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../shared/models/user.dart';

class TeamRepository {
  final _api = ApiClient.instance;

  Future<List<UserModel>> getTeamMembers() async {
    final response = await _api.get(ApiEndpoints.users);
    final results  = response.data['results'] as List? ?? response.data as List;
    return results
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admins de área de toda la organización (vista Super Admin — Equipo).
  Future<List<UserModel>> getAreaAdmins() async {
    final response = await _api.get(
      ApiEndpoints.users,
      params: {'role': 'admin_area'},
    );
    final results = response.data['results'] as List? ?? response.data as List;
    return results
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> getUserDetail(String userId) async {
    final response = await _api.get(ApiEndpoints.userDetail(userId));
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<UserModel>> getAreaMembers(String areaId) async {
    final response = await _api.get(ApiEndpoints.areaMembers(areaId));
    final results  = response.data as List? ?? [];
    return results
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Genera invitación. Retorna el token plano para compartir.
  Future<Map<String, dynamic>> generateInvite({
    required String areaId,
    required String role,
  }) async {
    final response = await _api.post(ApiEndpoints.inviteUser, data: {
      'area': areaId,
      'role': role,
    });
    // Retorna: { token, expires_at, role, area_id }
    return response.data as Map<String, dynamic>;
  }

  Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async {
    final response = await _api.patch(ApiEndpoints.userDetail(userId), data: data);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
