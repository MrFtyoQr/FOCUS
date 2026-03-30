import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../shared/models/project.dart';
import '../../../shared/models/activity.dart';

class ProjectRepository {
  final _api = ApiClient.instance;

  Future<List<ProjectModel>> getProjects() async {
    final res = await _api.get(ApiEndpoints.projects);
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => ProjectModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProjectModel> getProject(int id) async {
    final res = await _api.get(ApiEndpoints.projectDetail(id));
    return ProjectModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ActivityModel>> getProjectActivities(int id) async {
    final res = await _api.get(ApiEndpoints.activities, params: {'project_id': id});
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => ActivityModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProjectModel> createProject({required String name, String? description, String color = '#7F77DD'}) async {
    final res = await _api.post(ApiEndpoints.projects, data: {
      'name': name,
      if (description != null) 'description': description,
      'color': color,
    });
    return ProjectModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteProject(int id) async => _api.delete(ApiEndpoints.projectDetail(id));
}
