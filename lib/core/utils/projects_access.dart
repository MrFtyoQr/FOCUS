import '../../shared/models/project.dart';
import '../../shared/models/user.dart';
import '../../shared/enums/user_role.dart';
import 'project_kind.dart';

/// Proyectos personales creados por el usuario.
List<ProjectModel> personalProjectsOwnedBy(UserModel u, List<ProjectModel> all) {
  return all
      .where((p) => isPersonalProject(p) && p.createdById == u.id)
      .toList();
}

/// Proyectos de equipo (área) visibles para un AA o TA.
List<ProjectModel> teamProjectsForArea(UserModel u, List<ProjectModel> all) {
  final aid = u.areaId;
  if (aid == null || aid.isEmpty) return [];
  return all.where((p) => isTeamProject(p) && p.areaId == aid).toList();
}

/// Proyectos que puede elegir al capturar una actividad.
List<ProjectModel> projectsForCapture(UserModel u, List<ProjectModel> all) {
  switch (u.role) {
    case UserRole.personal:
      return personalProjectsOwnedBy(u, all);
    case UserRole.superAdmin:
      return personalProjectsOwnedBy(u, all);
    case UserRole.adminArea:
      return [
        ...personalProjectsOwnedBy(u, all),
        ...teamProjectsForArea(u, all),
      ];
    case UserRole.trabajador:
      return personalProjectsOwnedBy(u, all);
  }
}

/// Listado principal «Proyectos» — SA: solo personales propios.
List<ProjectModel> projectsMainListForUser(UserModel u, List<ProjectModel> all) {
  switch (u.role) {
    case UserRole.superAdmin:
      return personalProjectsOwnedBy(u, all);
    case UserRole.personal:
      return personalProjectsOwnedBy(u, all);
    case UserRole.adminArea:
      return [
        ...personalProjectsOwnedBy(u, all),
        ...teamProjectsForArea(u, all),
      ];
    case UserRole.trabajador:
      return [
        ...personalProjectsOwnedBy(u, all),
        ...teamProjectsForArea(u, all),
      ];
  }
}

/// Proyectos asignados por SA a un AA (equipo, no personales del AA).
List<ProjectModel> areaProjectsAssignedByOrg(UserModel u, List<ProjectModel> all) {
  if (!u.isAdminArea) return [];
  return teamProjectsForArea(u, all);
}

/// SA: proyectos creados para AA (listado filtrado «Para AA»).
List<ProjectModel> saProjectsForAreaAdmins(List<ProjectModel> all) {
  return all.where(isTeamProject).toList();
}
