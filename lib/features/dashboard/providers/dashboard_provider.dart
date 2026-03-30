import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/activity_repository.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/enums/activity_status.dart';

final activityRepositoryProvider = Provider((_) => ActivityRepository());

final activitiesProvider = FutureProvider.family<List<ActivityModel>, String?>(
  (ref, status) => ref.read(activityRepositoryProvider).getActivities(status: status),
);

final dashboardProvider = FutureProvider<Map<ActivityStatus, List<ActivityModel>>>((ref) async {
  final all = await ref.read(activityRepositoryProvider).getActivities();
  return {
    for (final s in ActivityStatus.values.where((s) => s != ActivityStatus.completada))
      s: all.where((a) => a.status == s).toList(),
  };
});
