import '../../shared/models/activity.dart';
import '../../shared/models/project.dart';
import '../../shared/models/user.dart';
import '../../shared/enums/user_role.dart';
import 'project_kind.dart';

/// Filtro del tablero para AA y TA.
enum ActivityDashboardScope {
  all,
  personal,
  team,
}

/// Actividad "personal" del usuario: es suya y (sin proyecto o proyecto personal).
bool isPersonalActivityForUser(
  UserModel user,
  ActivityModel a,
  Map<String, ProjectModel> projectsById,
) {
  if (a.ownerId != user.id) return false;
  if (a.isSinProyecto) return true;
  final p = projectsById[a.projectId];
  return p != null && isPersonalProject(p);
}

/// Actividad de equipo (área) para AA/TA con `areaId` definido.
bool isTeamActivityForUser(
  UserModel user,
  ActivityModel a,
  Map<String, ProjectModel> projectsById,
) {
  final aid = user.areaId;
  if (aid == null || aid.isEmpty) return false;
  if (!a.isSinProyecto) {
    final p = projectsById[a.projectId];
    if (p != null && isTeamProject(p) && p.areaId == aid) return true;
    return false;
  }
  return a.areaId == aid && a.ownerId != user.id;
}

/// Super Admin o cuenta personal: solo actividades personales propias.
bool isSuperAdminOrPersonalDashboardActivity(
  UserModel user,
  ActivityModel a,
  Map<String, ProjectModel> projectsById,
) {
  if (user.role != UserRole.superAdmin && user.role != UserRole.personal) {
    return false;
  }
  return isPersonalActivityForUser(user, a, projectsById);
}

/// Filtra actividades visibles en el tablero según rol y ámbito.
List<ActivityModel> filterActivitiesForDashboard({
  required UserModel user,
  required List<ActivityModel> all,
  required Map<String, ProjectModel> projectsById,
  ActivityDashboardScope scope = ActivityDashboardScope.all,
}) {
  bool allow(ActivityModel a) {
    switch (user.role) {
      case UserRole.superAdmin:
      case UserRole.personal:
        return isSuperAdminOrPersonalDashboardActivity(user, a, projectsById);
      case UserRole.adminArea:
      case UserRole.trabajador:
        final personal = isPersonalActivityForUser(user, a, projectsById);
        final team = isTeamActivityForUser(user, a, projectsById);
        return switch (scope) {
          ActivityDashboardScope.all => personal || team,
          ActivityDashboardScope.personal => personal,
          ActivityDashboardScope.team => team,
        };
    }
  }

  return all.where(allow).toList();
}

/// Actividades personales para métricas de productividad (mismo criterio que tablero).
List<ActivityModel> personalActivitiesForStats(
  UserModel user,
  List<ActivityModel> all,
  Map<String, ProjectModel> projectsById,
) {
  return all
      .where((a) => isPersonalActivityForUser(user, a, projectsById))
      .toList();
}

/// Actividades de equipo para métricas (AA/TA con área).
List<ActivityModel> teamActivitiesForStats(
  UserModel user,
  List<ActivityModel> all,
  Map<String, ProjectModel> projectsById,
) {
  if (user.areaId == null || user.areaId!.isEmpty) return [];
  return all
      .where((a) => isTeamActivityForUser(user, a, projectsById))
      .toList();
}
