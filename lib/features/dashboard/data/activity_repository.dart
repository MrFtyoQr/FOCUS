import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../shared/models/activity.dart';

class ActivityRepository {
  final _api = ApiClient.instance;

  /// [scope] reservado para API (`personal` | `team`); el cliente filtra con [activity_scope.dart] hasta que exista en backend.
  Future<List<ActivityModel>> getActivities({
    String? status,
    String? projectId,
    String? areaId,
    String? scope,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (projectId != null) params['project'] = projectId;
    if (areaId != null) params['area'] = areaId;
    if (scope != null) params['scope'] = scope;

    final response = await _api.get(ApiEndpoints.activities, params: params);
    final results = response.data['results'] as List? ?? response.data as List;
    return results
        .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ActivityModel> getActivity(String id) async {
    final response = await _api.get(ApiEndpoints.activityDetail(id));
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityModel> createActivity({
    required String title,
    String? description,
    required String status,
    String? projectId,
    String? areaId,
    String? assignedTo,
    DateTime? targetDate,
  }) async {
    final response = await _api.post(ApiEndpoints.activities, data: {
      'title': title,
      'status': status,
      if (description != null) 'description': description,
      if (projectId != null) 'project': projectId,
      if (areaId != null) 'area': areaId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (targetDate != null)
        'target_date': targetDate.toIso8601String().split('T')[0],
    });
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityModel> updateActivity(
      String id, Map<String, dynamic> data) async {
    final response =
        await _api.patch(ApiEndpoints.activityDetail(id), data: data);
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityModel> moveActivity(String id, String status) async {
    final response = await _api.post(
      ApiEndpoints.activityMove(id),
      data: {'status': status},
    );
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityModel> completeActivity(String id) async {
    final response = await _api.post(ApiEndpoints.activityComplete(id));
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityModel> assignActivity(String id, String assignedToId) async {
    final response = await _api.post(
      ApiEndpoints.activityAssign(id),
      data: {'assigned_to': assignedToId},
    );
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Quita la asignación (`assigned_to: null`).
  Future<ActivityModel> unassignActivity(String id) async {
    final response = await _api.post(
      ApiEndpoints.activityAssign(id),
      data: {'assigned_to': null},
    );
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteActivity(String id) async {
    await _api.delete(ApiEndpoints.activityDetail(id));
  }

  Future<List<Map<String, dynamic>>> getAttachments(String id) async {
    final response = await _api.get(ApiEndpoints.attachments(id));
    final d = response.data;
    final List raw =
        d is List ? d : (d is Map ? (d['results'] as List? ?? []) : []);
    return raw.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> uploadAttachment(
      String id, String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    await _api.upload(ApiEndpoints.attachments(id), formData);
  }

  Future<void> deleteAttachment(String actId, String attId) async {
    await _api.delete(ApiEndpoints.attachmentDelete(actId, attId));
  }

  Future<List<Map<String, dynamic>>> getLogs(String id) async {
    final response = await _api.get(ApiEndpoints.activityLogs(id));
    final d = response.data;
    final List raw =
        d is List ? d : (d is Map ? (d['results'] as List? ?? []) : []);
    return raw.map((e) => e as Map<String, dynamic>).toList();
  }
}

/// Mensaje legible al fallar `assign` / `unassign`: prioriza el campo `assigned_to` en 400.
String messageFromAssignApiError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (e.response?.statusCode == 400 && data is Map) {
      final v = data['assigned_to'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is List && v.isNotEmpty) {
        final first = v.first;
        if (first is String && first.trim().isNotEmpty) return first.trim();
        return first.toString();
      }
    }
    final msg = e.message;
    if (msg != null && msg.isNotEmpty) return msg;
  }
  final s = e.toString();
  return s.replaceFirst('Exception: ', '');
}
