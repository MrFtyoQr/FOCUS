import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/activity_repository.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/enums/activity_status.dart';

final activityRepositoryProvider = Provider((_) => ActivityRepository());

final activitiesProvider =
    FutureProvider.family<List<ActivityModel>, String?>((ref, status) async {
  final repo = ref.read(activityRepositoryProvider);
  return repo.getActivities(status: status);
});

final dashboardProvider =
    FutureProvider<Map<ActivityStatus, List<ActivityModel>>>((ref) async {
  final repo = ref.read(activityRepositoryProvider);
  final all  = await repo.getActivities();

  return {
    for (final status in ActivityStatus.values
        .where((s) => s != ActivityStatus.completada))
      status: all.where((a) => a.status == status).toList(),
  };
});
