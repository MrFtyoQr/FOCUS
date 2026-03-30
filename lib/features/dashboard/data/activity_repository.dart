import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../shared/models/activity.dart';

class ActivityRepository {
  final _api = ApiClient.instance;

  Future<List<ActivityModel>> getActivities({String? status, int? projectId}) async {
    final params = <String, dynamic>{};
    if (status != null)    params['status'] = status;
    if (projectId != null) params['project_id'] = projectId;
    final res = await _api.get(ApiEndpoints.activities, params: params);
    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => ActivityModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ActivityModel> getActivity(int id) async {
    final res = await _api.get(ApiEndpoints.activityDetail(id));
    return ActivityModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ActivityModel> createActivity({required String title, String? description, required String status, int? projectId, DateTime? targetDate}) async {
    final res = await _api.post(ApiEndpoints.activities, data: {
      'title': title,
      if (description != null) 'description': description,
      'status': status,
      if (projectId != null) 'project': projectId,
      if (targetDate != null) 'target_date': targetDate.toIso8601String().split('T')[0],
    });
    return ActivityModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ActivityModel> moveActivity(int id, String status) async {
    final res = await _api.patch(ApiEndpoints.activityMove(id), data: {'status': status});
    return ActivityModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ActivityModel> completeActivity(int id) async {
    final res = await _api.patch(ApiEndpoints.activityComplete(id));
    return ActivityModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ActivityModel> assignActivity(int id, int assignedToId) async {
    final res = await _api.patch(ApiEndpoints.activityAssign(id), data: {'assigned_to': assignedToId});
    return ActivityModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteActivity(int id) async => _api.delete(ApiEndpoints.activityDetail(id));
}
