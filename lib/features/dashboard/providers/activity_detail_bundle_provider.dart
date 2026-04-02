import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_provider.dart';
import '../../../shared/models/activity.dart';

/// Actividad + adjuntos + bitácora para la pantalla de detalle.
class ActivityDetailBundle {
  final ActivityModel activity;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> logs;

  const ActivityDetailBundle({
    required this.activity,
    required this.attachments,
    required this.logs,
  });
}

final activityDetailBundleProvider =
    FutureProvider.family<ActivityDetailBundle, String>((ref, actId) async {
  final repo = ref.watch(activityRepositoryProvider);
  final activity = await repo.getActivity(actId);
  final attachments = await repo.getAttachments(actId);
  final logs = await repo.getLogs(actId);
  return ActivityDetailBundle(
    activity: activity,
    attachments: attachments,
    logs: logs,
  );
});
