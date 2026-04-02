import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../dashboard/data/activity_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../shared/models/activity.dart';

/// Resultado de captura: actividad creada y nombres de archivos que no se pudieron subir.
class CaptureOutcome {
  final ActivityModel activity;
  final List<String> failedFiles;

  const CaptureOutcome(this.activity, {this.failedFiles = const []});

  bool get hasUploadFailures => failedFiles.isNotEmpty;
}

class CaptureNotifier extends StateNotifier<AsyncValue<void>> {
  final ActivityRepository _repo;
  final Ref _ref;

  CaptureNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<CaptureOutcome?> capture({
    required String title,
    String? description,
    required String status,
    String? projectId,
    String? areaId,
    DateTime? targetDate,
    List<String> attachmentPaths = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      final activity = await _repo.createActivity(
        title: title,
        description: description,
        status: status,
        projectId: projectId,
        areaId: areaId,
        targetDate: targetDate,
      );

      final failed = <String>[];
      for (final path in attachmentPaths) {
        try {
          await _repo.uploadAttachment(
            activity.id,
            path,
            p.basename(path),
          );
        } catch (_) {
          failed.add(p.basename(path));
        }
      }

      _ref.invalidate(dashboardProvider);
      state = const AsyncValue.data(null);
      return CaptureOutcome(activity, failedFiles: failed);
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
