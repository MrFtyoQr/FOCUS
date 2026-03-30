import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../shared/models/user.dart';

class TeamRepository {
  final _api = ApiClient.instance;

  Future<List<UserModel>> getTeamMembers() async {
    final res = await _api.get(ApiEndpoints.users);
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserModel>> getAreaMembers(int areaId) async {
    final res = await _api.get(ApiEndpoints.areaMembers(areaId));
    return (res.data as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> generateInviteLink({required String email, required String role, int? areaId}) async {
    final res = await _api.post(ApiEndpoints.inviteSend, data: {'email': email, 'role': role, if (areaId != null) 'area': areaId});
    return res.data['link'] as String;
  }
}
