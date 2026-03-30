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

  Future<List<UserModel>> getAreaMembers(int areaId) async {
    final response = await _api.get(ApiEndpoints.areaMembers(areaId));
    return (response.data as List)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> generateInviteLink({
    required String email,
    required String role,
    int? areaId,
  }) async {
    final response = await _api.post(ApiEndpoints.inviteSend, data: {
      'email': email,
      'role':  role,
      if (areaId != null) 'area': areaId,
    });
    return response.data['link'] as String;
  }
}
