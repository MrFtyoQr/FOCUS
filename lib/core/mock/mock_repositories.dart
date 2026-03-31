import 'dart:async';
import '../../features/auth/data/auth_repository.dart';
import '../../features/dashboard/data/activity_repository.dart';
import '../../features/projects/data/project_repository.dart';
import '../../features/team/data/team_repository.dart';
import '../../features/stats/data/stats_repository.dart';
import '../../shared/models/activity.dart';
import '../../shared/models/project.dart';
import '../../shared/models/user.dart';
import '../../shared/enums/activity_status.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/storage/local_prefs.dart';
import 'mock_data.dart';

// Simula latencia de red para que los estados loading/data se noten
Future<T> _fake<T>(T value, [int ms = 500]) async {
  await Future.delayed(Duration(milliseconds: ms));
  return value;
}

// ── Auth ──────────────────────────────────────────────────────────────────────
class MockAuthRepository extends AuthRepository {
  static const _mockAccess  = 'mock_access_token';
  static const _mockRefresh = 'mock_refresh_token';

  Future<void> _seedSession() async {
    await SecureStorage.instance.saveTokens(
      access: _mockAccess, refresh: _mockRefresh,
    );
    await LocalPrefs.instance.setOnboardingCompleted();
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    await _seedSession();
    return MockData.currentUser;
  }

  @override
  Future<UserModel> getMe() => _fake(MockData.currentUser, 300);

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await SecureStorage.instance.clearAll();
  }

  @override
  Future<UserModel> acceptInvitation({
    required String token,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    await _seedSession();
    return UserModel(
      id: 'uuid-user-99', email: email,
      firstName: firstName, lastName: lastName,
      role: MockData.currentUser.role,
      areaId: MockData.currentUser.areaId,
      areaName: MockData.currentUser.areaName,
      onboardingCompleted: true,
    );
  }
}

// ── Activities ────────────────────────────────────────────────────────────────
class MockActivityRepository extends ActivityRepository {
  final _activities = List<ActivityModel>.from(MockData.activities);
  int _nextIdx = 100;

  @override
  Future<List<ActivityModel>> getActivities({
    String? status,
    String? projectId,
    String? areaId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    var list = _activities.toList();
    if (status    != null) list = list.where((a) => a.status.apiValue == status).toList();
    if (projectId != null) list = list.where((a) => a.projectId == projectId).toList();
    if (areaId    != null) list = list.where((a) => a.areaId == areaId).toList();
    return list;
  }

  @override
  Future<ActivityModel> getActivity(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _activities.firstWhere((a) => a.id == id);
  }

  @override
  Future<ActivityModel> createActivity({
    required String title,
    String? description,
    required String status,
    String? projectId,
    String? areaId,
    String? assignedTo,
    DateTime? targetDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    final activity = ActivityModel(
      id: 'uuid-act-$_nextIdx',
      title: title,
      description: description ?? '',
      status: ActivityStatus.fromString(status),
      ownerId: MockData.currentUser.id,
      ownerName: MockData.currentUser.fullName,
      projectId: projectId,
      projectName: projectId != null
          ? MockData.projects.firstWhere((p) => p.id == projectId).name
          : null,
      areaId: areaId ?? MockData.currentUser.areaId,
      targetDate: targetDate,
      createdAt: now,
      updatedAt: now,
    );
    _nextIdx++;
    _activities.add(activity);
    return activity;
  }

  @override
  Future<ActivityModel> moveActivity(String id, String status) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _activities.indexWhere((a) => a.id == id);
    final src = _activities[idx];
    final updated = ActivityModel(
      id: src.id, title: src.title, description: src.description,
      status: ActivityStatus.fromString(status),
      ownerId: src.ownerId, ownerName: src.ownerName,
      assignedToId: src.assignedToId, assignedToName: src.assignedToName,
      assignedById: src.assignedById, assignedByName: src.assignedByName,
      projectId: src.projectId, projectName: src.projectName,
      areaId: src.areaId, areaName: src.areaName,
      targetDate: src.targetDate,
      createdAt: src.createdAt, updatedAt: DateTime.now(),
    );
    _activities[idx] = updated;
    return updated;
  }

  @override
  Future<ActivityModel> completeActivity(String id) => moveActivity(id, 'completed');

  @override
  Future<ActivityModel> assignActivity(String id, String assignedToId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final member = MockData.teamMembers.firstWhere((m) => m.id == assignedToId);
    final idx    = _activities.indexWhere((a) => a.id == id);
    final src    = _activities[idx];
    final updated = ActivityModel(
      id: src.id, title: src.title, description: src.description,
      status: src.status,
      ownerId: src.ownerId, ownerName: src.ownerName,
      assignedToId: assignedToId, assignedToName: member.fullName,
      assignedById: MockData.currentUser.id, assignedByName: MockData.currentUser.fullName,
      projectId: src.projectId, projectName: src.projectName,
      areaId: src.areaId, areaName: src.areaName,
      targetDate: src.targetDate,
      createdAt: src.createdAt, updatedAt: DateTime.now(),
    );
    _activities[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteActivity(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _activities.removeWhere((a) => a.id == id);
  }
}

// ── Projects ──────────────────────────────────────────────────────────────────
class MockProjectRepository extends ProjectRepository {
  final _projects = List<ProjectModel>.from(MockData.projects);

  @override
  Future<List<ProjectModel>> getProjects() => _fake(List.from(_projects));

  @override
  Future<ProjectModel> getProject(String id) =>
      _fake(_projects.firstWhere((p) => p.id == id));

  @override
  Future<List<ActivityModel>> getProjectActivities(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockData.activities.where((a) => a.projectId == id).toList();
  }

  @override
  Future<Map<String, dynamic>> getProjectProgress(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final acts = MockData.activities.where((a) => a.projectId == id).toList();
    final completed = acts.where((a) => a.isCompleted).length;
    return {
      'total': acts.length, 'completed': completed,
      'pending': acts.length - completed, 'in_progress': 0,
      'completion_percentage': acts.isEmpty ? 0.0 : completed / acts.length * 100,
    };
  }

  @override
  Future<ProjectModel> createProject({
    required String name,
    String? areaId,
    String? description,
    String status = 'active',
    String? targetDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final p = ProjectModel(
      id: 'uuid-proj-${_projects.length + 10}',
      name: name, description: description ?? '',
      status: status, areaId: areaId,
      areaName: MockData.currentUser.areaName,
      createdAt: DateTime.now(),
    );
    _projects.add(p);
    return p;
  }

  @override
  Future<void> deleteProject(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _projects.removeWhere((p) => p.id == id);
  }
}

// ── Team ──────────────────────────────────────────────────────────────────────
class MockTeamRepository extends TeamRepository {
  @override
  Future<List<UserModel>> getTeamMembers() => _fake(MockData.teamMembers);

  @override
  Future<List<UserModel>> getAreaMembers(String areaId) =>
      _fake(MockData.teamMembers.where((m) => m.areaId == areaId).toList());

  @override
  Future<Map<String, dynamic>> generateInvite({
    required String areaId,
    required String role,
  }) => _fake({
    'token': 'mock-invite-token-abc123',
    'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
    'role': role,
    'area_id': areaId,
  });
}

// ── Stats ─────────────────────────────────────────────────────────────────────
class MockStatsRepository extends StatsRepository {
  @override
  Future<Map<String, dynamic>> getPersonalStats() => _fake(MockData.myStats);

  @override
  Future<Map<String, dynamic>> getAreaStats(String areaId) =>
      _fake(MockData.areaStats);

  @override
  Future<List<Map<String, dynamic>>> getWorkerStats() =>
      _fake(MockData.workerStats);

  @override
  Future<List<Map<String, dynamic>>> getAllAreasStats() =>
      _fake(MockData.allAreasStats);

  @override
  Future<Map<String, dynamic>> getDrilldown({
    String? areaId, String? projectId, String? userId,
    String? from, String? to,
  }) => _fake({
    'filters': {'area': areaId, 'project': projectId, 'user': userId},
    'summary': {'total': 74, 'completed': 58, 'completion_rate': 78.4},
    'by_project': [], 'by_user': MockData.workerStats, 'by_area': MockData.allAreasStats,
  });
}
