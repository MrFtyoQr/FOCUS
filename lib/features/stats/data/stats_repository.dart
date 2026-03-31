import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class StatsRepository {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> getPersonalStats() async {
    final response = await _api.get(ApiEndpoints.statsPersonal);
    return response.data as Map<String, dynamic>;
  }

  // Alias usado por la UI (trabajador)
  Future<Map<String, dynamic>> getMyStats() => getPersonalStats();

  Future<Map<String, dynamic>> getAreaStats(String areaId) async {
    final response = await _api.get(ApiEndpoints.statsArea(areaId));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDrilldown({
    String? areaId,
    String? projectId,
    String? userId,
    String? from,
    String? to,
  }) async {
    final params = <String, dynamic>{};
    if (areaId    != null) params['area']    = areaId;
    if (projectId != null) params['project'] = projectId;
    if (userId    != null) params['user']    = userId;
    if (from      != null) params['from']    = from;
    if (to        != null) params['to']      = to;

    final response = await _api.get(ApiEndpoints.statsDrilldown, params: params);
    return response.data as Map<String, dynamic>;
  }

  /// Lista de stats por trabajador para adminArea
  Future<List<Map<String, dynamic>>> getWorkerStats() async {
    final response = await _api.get(
      ApiEndpoints.statsDrilldown,
      params: {'by': 'user'},
    );
    final list = (response.data['by_user'] as List?) ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Lista de stats por área para superAdmin
  Future<List<Map<String, dynamic>>> getAllAreasStats() async {
    final response = await _api.get(
      ApiEndpoints.statsDrilldown,
      params: {'by': 'area'},
    );
    final list = (response.data['by_area'] as List?) ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
}
