import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  /// Usuario devuelto por el último login mock (para que `getMe` coincida con la sesión).
  static UserModel? _sessionUser;

  /// `MOCK_ACT_AS` en [app.env] fuerza el rol en mock sin depender del correo:
  /// `super_admin` | `sa` | `admin_area` | `aa` | `trabajador` | `ta` | `personal`.
  static UserModel? _mockUserForcedByEnv() {
    final act = dotenv.env['MOCK_ACT_AS']?.trim().toLowerCase();
    if (act == null || act.isEmpty) return null;
    if (act == 'super_admin' || act == 'superadmin' || act == 'sa') {
      return MockData.superAdminUser;
    }
    if (act == 'admin_area' || act == 'adminarea' || act == 'aa') {
      return MockData.currentUser;
    }
    if (act == 'trabajador' || act == 'worker' || act == 'empleado' || act == 'ta') {
      return MockData.teamMembers.firstWhere((u) => u.isTrabajador);
    }
    if (act == 'personal' || act == 'solo' || act == 'usuario') {
      return MockData.personalOnlyUser;
    }
    return null;
  }

  /// Usuario efectivo de la sesión mock (crear actividad, asignaciones, etc.).
  static UserModel get effectiveSessionUser =>
      _sessionUser ?? _mockUserForcedByEnv() ?? MockData.currentUser;

  /// Muestra en perfil el correo con el que se hizo login (mismo rol mock).
  static UserModel _withLoginEmail(UserModel user, String rawEmail) {
    final typed = rawEmail.trim();
    if (typed.isEmpty || !user.isSuperAdmin) return user;
    if (typed.toLowerCase() == user.email.toLowerCase()) return user;
    return UserModel(
      id: user.id,
      email: typed,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      areaId: user.areaId,
      areaName: user.areaName,
      biometricsEnabled: user.biometricsEnabled,
      onboardingCompleted: user.onboardingCompleted,
    );
  }

  static UserModel _userForEmail(String email) {
    final forced = _mockUserForcedByEnv();
    if (forced != null) return forced;

    final e = email.toLowerCase().trim();
    if (e == 'admin@focus.com' ||
        e.contains('superadmin') ||
        e.startsWith('sa@') ||
        e.endsWith('@super.treetech.mx')) {
      return MockData.superAdminUser;
    }
    if (e.startsWith('personal@') || e.contains('solo@')) {
      return MockData.personalOnlyUser;
    }
    return MockData.currentUser;
  }

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
    _sessionUser = _withLoginEmail(_userForEmail(email), email);
    return _sessionUser!;
  }

  @override
  Future<UserModel> getMe() {
    final forced = _mockUserForcedByEnv();
    final user = _sessionUser ?? forced ?? MockData.currentUser;
    return _fake(user, 300);
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _sessionUser = null;
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
    String? scope,
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
    final me = MockAuthRepository.effectiveSessionUser;
    final activity = ActivityModel(
      id: 'uuid-act-$_nextIdx',
      title: title,
      description: description ?? '',
      status: ActivityStatus.fromString(status),
      ownerId: me.id,
      ownerName: me.fullName,
      projectId: projectId,
      projectName: projectId != null
          ? MockData.projects.firstWhere((p) => p.id == projectId).name
          : null,
      areaId: areaId ?? me.areaId,
      targetDate: targetDate,
      createdAt: now,
      updatedAt: now,
    );
    _nextIdx++;
    _activities.add(activity);
    return activity;
  }

  @override
  Future<void> uploadAttachment(String id, String filePath, String fileName) async {
    await Future.delayed(const Duration(milliseconds: 200));
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
      assignedById: MockAuthRepository.effectiveSessionUser.id,
      assignedByName: MockAuthRepository.effectiveSessionUser.fullName,
      projectId: src.projectId, projectName: src.projectName,
      areaId: src.areaId, areaName: src.areaName,
      targetDate: src.targetDate,
      createdAt: src.createdAt, updatedAt: DateTime.now(),
    );
    _activities[idx] = updated;
    return updated;
  }

  @override
  Future<ActivityModel> unassignActivity(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _activities.indexWhere((a) => a.id == id);
    final src = _activities[idx];
    final updated = ActivityModel(
      id: src.id, title: src.title, description: src.description,
      status: src.status,
      ownerId: src.ownerId, ownerName: src.ownerName,
      assignedToId: null, assignedToName: null,
      assignedById: src.assignedById, assignedByName: src.assignedByName,
      projectId: src.projectId, projectName: src.projectName,
      areaId: src.areaId, areaName: src.areaName,
      targetDate: src.targetDate,
      completedAt: src.completedAt,
      createdAt: src.createdAt, updatedAt: DateTime.now(),
    );
    _activities[idx] = updated;
    return updated;
  }

  @override
  Future<ActivityModel> updateActivity(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _activities.indexWhere((a) => a.id == id);
    final s = _activities[idx];
    final title = data['title'] as String? ?? s.title;
    final description = data['description'] as String? ?? s.description;
    final status = data['status'] != null
        ? ActivityStatus.fromString(data['status'] as String)
        : s.status;
    final projectId = data.containsKey('project')
        ? data['project'] as String?
        : s.projectId;
    DateTime? targetDate = s.targetDate;
    if (data.containsKey('target_date')) {
      final td = data['target_date'];
      if (td == null) {
        targetDate = null;
      } else if (td is String) {
        targetDate = DateTime.tryParse(td);
      }
    }
    String? projectName = s.projectName;
    if (projectId != null) {
      try {
        projectName =
            MockData.projects.firstWhere((p) => p.id == projectId).name;
      } catch (_) {
        projectName = s.projectName;
      }
    } else {
      projectName = null;
    }
    final updated = ActivityModel(
      id: s.id,
      title: title,
      description: description,
      status: status,
      ownerId: s.ownerId,
      ownerName: s.ownerName,
      assignedToId: s.assignedToId,
      assignedToName: s.assignedToName,
      assignedById: s.assignedById,
      assignedByName: s.assignedByName,
      projectId: projectId,
      projectName: projectName,
      areaId: s.areaId,
      areaName: s.areaName,
      targetDate: targetDate,
      completedAt: s.completedAt,
      createdAt: s.createdAt,
      updatedAt: DateTime.now(),
    );
    _activities[idx] = updated;
    return updated;
  }

  @override
  Future<List<Map<String, dynamic>>> getAttachments(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getLogs(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {
        'type': 'create',
        'description': 'Actividad registrada (mock)',
        'timestamp': DateTime.now().toIso8601String(),
      },
    ];
  }

  @override
  Future<void> deleteAttachment(String actId, String attId) async {
    await Future.delayed(const Duration(milliseconds: 200));
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
    String? color,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    String? resolvedAreaName;
    String? resolvedAdminName;
    for (final row in MockData.allAreasStats) {
      if (row['area_id'] == areaId) {
        resolvedAreaName = row['area_name'] as String?;
        resolvedAdminName = row['admin_name'] as String?;
        break;
      }
    }
    resolvedAreaName ??= MockData.currentUser.areaName;
    final me = MockAuthRepository.effectiveSessionUser;
    final p = ProjectModel(
      id: 'uuid-proj-${_projects.length + 10}',
      name: name,
      description: description ?? '',
      status: status,
      areaId: areaId,
      areaName: resolvedAreaName,
      areaAdminName: resolvedAdminName,
      createdById: areaId == null || areaId.isEmpty ? me.id : null,
      createdAt: DateTime.now(),
      color: color ?? '#7F77DD',
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
  Future<List<UserModel>> getAreaAdmins() =>
      _fake(MockData.areaAdminsList);

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
      _fake(MockData.buildAreaStatsForOrphans(areaId));

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
