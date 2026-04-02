import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/activity_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../shared/enums/user_role.dart';
import '../../../core/utils/activity_scope.dart';
import '../../../core/utils/project_kind.dart';

final activityRepositoryProvider = Provider((_) => ActivityRepository());

final activitiesProvider =
    FutureProvider.family<List<ActivityModel>, String?>((ref, status) async {
  final repo = ref.read(activityRepositoryProvider);
  return repo.getActivities(status: status);
});

/// Ámbito del tablero para AA y TA (SA y cuenta personal siempre personales).
final dashboardScopeUiProvider =
    StateProvider<ActivityDashboardScope>((ref) => ActivityDashboardScope.all);

/// Tablero filtrado por rol y ámbito.
final dashboardProvider =
    FutureProvider<Map<ActivityStatus, List<ActivityModel>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final scopeUi = ref.watch(dashboardScopeUiProvider);
  final repo = ref.read(activityRepositoryProvider);
  final all = await repo.getActivities();
  final projects = await ref.watch(projectsProvider.future);
  final byId = projectMap(projects);

  ActivityDashboardScope scope;
  if (user == null) {
    scope = ActivityDashboardScope.personal;
  } else if (user.role == UserRole.superAdmin ||
      user.role == UserRole.personal) {
    scope = ActivityDashboardScope.personal;
  } else {
    scope = scopeUi;
  }

  final filtered = user == null
      ? <ActivityModel>[]
      : filterActivitiesForDashboard(
          user: user,
          all: all,
          projectsById: byId,
          scope: scope,
        );

  return {
    for (final status in ActivityStatus.values
        .where((s) => s != ActivityStatus.completada))
      status: filtered.where((a) => a.status == status).toList(),
  };
});

/// Todas las actividades (sin filtrar por rol). Historial y detalle.
final allActivitiesProvider =
    FutureProvider<List<ActivityModel>>((ref) async {
  final repo = ref.read(activityRepositoryProvider);
  return repo.getActivities();
});
