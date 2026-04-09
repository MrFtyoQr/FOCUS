import '../../shared/models/user.dart';

/// Trabajadores a mostrar en el selector de asignación según el usuario actual.
///
/// - **SuperAdmin:** todos los trabajadores devueltos por `GET /api/users/?role=trabajador`.
/// - **Admin de área:** solo trabajadores con `areaId` igual al del AA.
/// - **Otros roles:** lista vacía (no deberían abrir el flujo de asignación).
List<UserModel> workersForAssignmentPicker({
  required List<UserModel> workersFromApi,
  required UserModel? currentUser,
}) {
  final u = currentUser;
  if (u == null) return [];
  if (u.isSuperAdmin) return List<UserModel>.from(workersFromApi);
  if (u.isAdminArea) {
    final aid = u.areaId;
    if (aid == null) return [];
    return workersFromApi.where((w) => w.areaId == aid).toList();
  }
  return [];
}
