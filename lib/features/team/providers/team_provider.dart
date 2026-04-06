import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/team_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../shared/models/user.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/models/project.dart';

final teamRepositoryProvider = Provider((_) => TeamRepository());

final teamMembersProvider = FutureProvider<List<UserModel>>((ref) {
  return ref.read(teamRepositoryProvider).getTeamMembers();
});

final areaMembersProvider =
    FutureProvider.family<List<UserModel>, String>((ref, areaId) {
  return ref.read(teamRepositoryProvider).getAreaMembers(areaId);
});

/// Datos para la pantalla Equipo: miembros + actividades agrupadas por `assignedToId`.
class TeamScreenData {
  final List<UserModel> members;
  final Map<String, List<ActivityModel>> activitiesByAssigneeId;

  const TeamScreenData({
    required this.members,
    required this.activitiesByAssigneeId,
  });

  List<ActivityModel> activitiesFor(String userId) =>
      activitiesByAssigneeId[userId] ?? const [];
}

final teamScreenDataProvider = FutureProvider<TeamScreenData>((ref) async {
  final members = await ref
      .read(teamRepositoryProvider)
      .getTeamMembers()
      .catchError((_) => <UserModel>[]);
  final activities = await ref
      .read(activityRepositoryProvider)
      .getActivities()
      .catchError((_) => <ActivityModel>[]);
  final map = <String, List<ActivityModel>>{};
  for (final a in activities) {
    final id = a.assignedToId;
    if (id != null) {
      map.putIfAbsent(id, () => []).add(a);
    }
  }
  return TeamScreenData(members: members, activitiesByAssigneeId: map);
});

/// Tarjeta Equipo (Super Admin): un admin de área con proyectos, TA y avance.
class SaTeamAdminCardData {
  final UserModel admin;
  final List<ProjectModel> projects;
  final List<UserModel> trabajadores;
  /// `projectId` → completadas / total (0…1).
  final Map<String, double> projectProgress;

  const SaTeamAdminCardData({
    required this.admin,
    required this.projects,
    required this.trabajadores,
    required this.projectProgress,
  });
}

final teamScreenSaDataProvider =
    FutureProvider<List<SaTeamAdminCardData>>((ref) async {
  final repo = ref.read(teamRepositoryProvider);
  // Si el backend falla (timeout, 500) devolvemos listas vacías en lugar de
  // propagar la excepción y romper toda la pantalla Equipo.
  final admins = await repo
      .getAreaAdmins()
      .catchError((_) => <UserModel>[]);
  final allProjects = await ref
      .read(projectsProvider.future)
      .catchError((_) => <ProjectModel>[]);
  final activities = await ref
      .read(activityRepositoryProvider)
      .getActivities()
      .catchError((_) => <ActivityModel>[]);

  final out = <SaTeamAdminCardData>[];
  for (final aa in admins) {
    final aid = aa.areaId;
    final projects = aid == null
        ? <ProjectModel>[]
        : allProjects.where((p) => p.areaId == aid).toList();
    final workers = aid == null
        ? <UserModel>[]
        : (await repo.getAreaMembers(aid))
            .where((u) => u.isTrabajador)
            .toList();

    final progress = <String, double>{};
    for (final p in projects) {
      final acts = activities.where((a) => a.projectId == p.id).toList();
      final tot = acts.length;
      final done =
          acts.where((a) => a.status == ActivityStatus.completada).length;
      progress[p.id] = tot == 0 ? 0.0 : done / tot;
    }

    out.add(SaTeamAdminCardData(
      admin: aa,
      projects: projects,
      trabajadores: workers,
      projectProgress: progress,
    ));
  }
  double avgProgress(SaTeamAdminCardData d) {
    if (d.projectProgress.isEmpty) return 0;
    final v = d.projectProgress.values.toList();
    return v.reduce((a, b) => a + b) / v.length;
  }

  out.sort((a, b) => avgProgress(b).compareTo(avgProgress(a)));
  return out;
});
