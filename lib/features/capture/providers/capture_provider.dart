import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/data/activity_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../shared/models/activity.dart';

class CaptureNotifier extends StateNotifier<AsyncValue<void>> {
  final ActivityRepository _repo;
  final Ref _ref;

  CaptureNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<ActivityModel?> capture({
    required String title,
    String? description,
    required String status,
    String? projectId,
    String? areaId,
    DateTime? targetDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final activity = await _repo.createActivity(
        title:       title,
        description: description,
        status:      status,
        projectId:   projectId,
        areaId:      areaId,
        targetDate:  targetDate,
      );
      _ref.invalidate(dashboardProvider);
      state = const AsyncValue.data(null);
      return activity;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final captureProvider =
    StateNotifierProvider<CaptureNotifier, AsyncValue<void>>(
  (ref) => CaptureNotifier(ref.read(activityRepositoryProvider), ref),
);
