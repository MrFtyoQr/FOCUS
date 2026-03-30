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
import 'mock_data.dart';

// Simula latencia de red para que los estados loading/data se noten
Future<T> _fake<T>(T value, [int ms = 500]) async {
  await Future.delayed(Duration(milliseconds: ms));
  return value;
}

// ── Auth ──────────────────────────────────────────────────────────────────────
class MockAuthRepository extends AuthRepository {
  @override
  Future<UserModel> login({required String email, required String password}) =>
      _fake(MockData.currentUser, 800);

  @override
  Future<UserModel> register({required String email, required String firstName,
      required String lastName, required String password}) =>
      _fake(MockData.currentUser, 800);

  @override
  Future<UserModel> getMe() => _fake(MockData.currentUser, 300);

  @override
  Future<void> logout() async => Future.delayed(const Duration(milliseconds: 300));

  @override
  Future<Map<String, dynamic>> validateInviteToken(String token) =>
      _fake({'email': 'invited@treetech.mx', 'role': 'trabajador'});
}

// ── Activities ────────────────────────────────────────────────────────────────
class MockActivityRepository extends ActivityRepository {
  // Lista mutable para que createActivity sea visible en el tablero
  final _activities = List<ActivityModel>.from(MockData.activities);
  int _nextId = 100;

  @override
  Future<List<ActivityModel>> getActivities({String? status, int? projectId}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    var list = _activities.toList();
    if (status != null) {
      list = list.where((a) => a.status.name == status).toList();
    }
    if (projectId != null) {
      list = list.where((a) => a.projectId == projectId).toList();
    }
    return list;
  }

  @override
  Future<ActivityModel> getActivity(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _activities.firstWhere((a) => a.id == id);
  }

  @override
  Future<ActivityModel> createActivity({
    required String title,
    String? description,
    required String status,
    int? projectId,
    DateTime? targetDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    final activity = ActivityModel(
      id: _nextId++,
      title: title,
      description: description ?? '',
      status: ActivityStatus.fromString(status),
      ownerId: MockData.currentUser.id,
      ownerName: MockData.currentUser.fullName,
      projectId: projectId,
      projectName: projectId != null
          ? MockData.projects.firstWhere((p) => p.id == projectId).name
          : null,
      targetDate: targetDate,
      createdAt: now,
      updatedAt: now,
    );
    _activities.add(activity);
    return activity;
  }

  @override
  Future<ActivityModel> moveActivity(int id, String status) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _activities.indexWhere((a) => a.id == id);
    final updated = ActivityModel(
      id: _activities[idx].id,
      title: _activities[idx].title,
      description: _activities[idx].description,
      status: ActivityStatus.fromString(status),
      ownerId: _activities[idx].ownerId,
      ownerName: _activities[idx].ownerName,
      assignedToId: _activities[idx].assignedToId,
      assignedToName: _activities[idx].assignedToName,
      assignedById: _activities[idx].assignedById,
      assignedByName: _activities[idx].assignedByName,
      projectId: _activities[idx].projectId,
      projectName: _activities[idx].projectName,
      targetDate: _activities[idx].targetDate,
      createdAt: _activities[idx].createdAt,
      updatedAt: DateTime.now(),
    );
    _activities[idx] = updated;
    return updated;
  }

  @override
  Future<ActivityModel> completeActivity(int id) => moveActivity(id, 'completada');

  @override
  Future<ActivityModel> assignActivity(int id, int assignedToId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final member = MockData.teamMembers.firstWhere((m) => m.id == assignedToId);
    final idx    = _activities.indexWhere((a) => a.id == id);
    final updated = ActivityModel(
      id: _activities[idx].id,
      title: _activities[idx].title,
      description: _activities[idx].description,
      status: _activities[idx].status,
      ownerId: _activities[idx].ownerId,
      ownerName: _activities[idx].ownerName,
      assignedToId: assignedToId,
      assignedToName: member.fullName,
      assignedById: MockData.currentUser.id,
      assignedByName: MockData.currentUser.fullName,
      projectId: _activities[idx].projectId,
      projectName: _activities[idx].projectName,
      targetDate: _activities[idx].targetDate,
      createdAt: _activities[idx].createdAt,
      updatedAt: DateTime.now(),
    );
    _activities[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteActivity(int id) async {
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
  Future<ProjectModel> getProject(int id) =>
      _fake(_projects.firstWhere((p) => p.id == id));

  @override
  Future<List<ActivityModel>> getProjectActivities(int id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockData.activities.where((a) => a.projectId == id).toList();
  }

  @override
  Future<ProjectModel> createProject({required String name, String? description, String color = '#7F77DD'}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final p = ProjectModel(
      id: _projects.length + 10,
      name: name, description: description ?? '', color: color,
      ownerId: MockData.currentUser.id, ownerName: MockData.currentUser.fullName,
      areaId: MockData.currentUser.areaId, areaName: MockData.currentUser.areaName,
      totalActivities: 0, completedActivities: 0,
      createdAt: DateTime.now(),
    );
    _projects.add(p);
    return p;
  }

  @override
  Future<void> deleteProject(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _projects.removeWhere((p) => p.id == id);
  }
}

// ── Team ──────────────────────────────────────────────────────────────────────
class MockTeamRepository extends TeamRepository {
  @override
  Future<List<UserModel>> getTeamMembers() => _fake(MockData.teamMembers);

  @override
  Future<List<UserModel>> getAreaMembers(int areaId) =>
      _fake(MockData.teamMembers.where((m) => m.areaId == areaId).toList());

  @override
  Future<String> generateInviteLink({required String email, required String role, int? areaId}) =>
      _fake('https://hiperapp.treetech.mx/invite/mock-token-abc123');
}

// ── Stats ─────────────────────────────────────────────────────────────────────
class MockStatsRepository extends StatsRepository {
  @override
  Future<Map<String, dynamic>> getMyStats()           => _fake(MockData.myStats);
  @override
  Future<Map<String, dynamic>> getAreaStats()         => _fake(MockData.areaStats);
  @override
  Future<Map<String, dynamic>> getAreaDetailStats(int areaId) => _fake(MockData.areaStats);
}
