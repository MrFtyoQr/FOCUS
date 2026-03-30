import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class StatsRepository {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> getMyStats()                 async => (await _api.get(ApiEndpoints.statsMe)).data   as Map<String, dynamic>;
  Future<Map<String, dynamic>> getAreaStats()               async => (await _api.get(ApiEndpoints.statsArea)).data  as Map<String, dynamic>;
  Future<Map<String, dynamic>> getAreaDetailStats(int id)   async => (await _api.get(ApiEndpoints.statsAreaDetail(id))).data as Map<String, dynamic>;
}
