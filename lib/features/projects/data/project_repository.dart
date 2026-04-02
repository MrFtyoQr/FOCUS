import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../shared/models/project.dart';
import '../../../shared/models/activity.dart';

class ProjectRepository {
  final _api = ApiClient.instance;

  Future<List<ProjectModel>> getProjects() async {
    final response = await _api.get(ApiEndpoints.projects);
    final results  = response.data['results'] as List? ?? response.data as List;
    return results
        .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectModel> getProject(String id) async {
    final response = await _api.get(ApiEndpoints.projectDetail(id));
    return ProjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ActivityModel>> getProjectActivities(String id) async {
    final response = await _api.get(ApiEndpoints.projectActivities(id));
    final results  = response.data['results'] as List? ?? response.data as List;
    return results
        .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getProjectProgress(String id) async {
    final response = await _api.get(ApiEndpoints.projectProgress(id));
    return response.data as Map<String, dynamic>;
  }

  Future<ProjectModel> createProject({
    required String name,
    String? areaId,
    String? description,
    String status = 'active',
    String? targetDate,
    String? color,
  }) async {
    final response = await _api.post(ApiEndpoints.projects, data: {
      'name':   name,
      'status': status,
      if (areaId      != null) 'area':         areaId,
      if (description != null) 'description':  description,
      if (targetDate  != null) 'target_date':  targetDate,
      if (color       != null) 'color':        color,
    });
    return ProjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProjectModel> updateProject(String id, Map<String, dynamic> data) async {
    final response = await _api.patch(ApiEndpoints.projectDetail(id), data: data);
    return ProjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteProject(String id) async {
    await _api.delete(ApiEndpoints.projectDetail(id));
  }
}
