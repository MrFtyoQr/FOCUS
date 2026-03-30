import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class StatsRepository {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> getMyStats() async {
    final response = await _api.get(ApiEndpoints.statsMe);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAreaStats() async {
    final response = await _api.get(ApiEndpoints.statsArea);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAreaDetailStats(int areaId) async {
    final response = await _api.get(ApiEndpoints.statsAreaDetail(areaId));
    return response.data as Map<String, dynamic>;
  }
}
