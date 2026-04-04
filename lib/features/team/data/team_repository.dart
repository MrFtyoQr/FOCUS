import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../shared/models/user.dart';

/// Extrae el primer mensaje de error legible de una [DioException].
String _parseTeamError(DioException e, {String fallback = 'Error inesperado'}) {
  final data = e.response?.data;
  if (data is Map) {
    final values = data.values.whereType<Object>().toList();
    if (values.isNotEmpty) {
      final first = values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
  }
  if (data is String && data.isNotEmpty) return data;
  return e.message ?? fallback;
}

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
        .where((u) => u.isAdminArea)
        .toList();
  }

  Future<UserModel> getUserDetail(String userId) async {
    final response = await _api.get(ApiEndpoints.userDetail(userId));
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<UserModel>> getAreaMembers(String areaId) async {
    final response = await _api.get(ApiEndpoints.areaMembers(areaId));
    final results  = response.data['results'] as List? ?? response.data as List? ?? [];
    return results
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lista de áreas de la organización. Retorna: [{id, name, description?}]
  Future<List<Map<String, dynamic>>> getAreas() async {
    final response = await _api.get(ApiEndpoints.areas);
    final list = response.data['results'] as List? ?? response.data as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Crea un área. Retorna: {id, name, description?}
  Future<Map<String, dynamic>> createArea({
    required String name,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{'name': name};
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }
      final response = await _api.post(ApiEndpoints.areas, data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_parseTeamError(e, fallback: 'No se pudo crear el área'));
    }
  }

  /// Genera invitación. [areaId] es null para rol super_admin.
  /// Retorna: { code, token, expires_at, role, area_id? }
  ///
  /// Lanza [Exception] con mensaje legible si el backend rechaza la solicitud
  /// (ej. 403 por permisos de AA, 429 por rate limit).
  Future<Map<String, dynamic>> generateInvite({
    String? areaId,
    required String role,
  }) async {
    try {
      final body = <String, dynamic>{'role': role};
      if (areaId != null && areaId.isNotEmpty) body['area'] = areaId;
      final response = await _api.post(ApiEndpoints.inviteUser, data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        _parseTeamError(e, fallback: 'No se pudo generar la invitación'),
      );
    }
  }

  Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async {
    final response = await _api.patch(ApiEndpoints.userDetail(userId), data: data);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
