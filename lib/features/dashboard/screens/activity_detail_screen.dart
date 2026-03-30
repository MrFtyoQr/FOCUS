import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/activity.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final int id;
  const ActivityDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activitiesProvider(null));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: e.toString()),
        data: (activities) {
          final ActivityModel? activity = activities.where((a) => a.id == id).isNotEmpty
              ? activities.firstWhere((a) => a.id == id)
              : null;
          if (activity == null) return const EmptyState(icon: Icons.inbox, title: 'No encontrada', subtitle: 'La actividad no existe');

          final color = AppColors.statusColor(activity.status.name);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(activity.status.label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              const SizedBox(height: 16),
              Text(activity.title, style: AppTextStyles.heading1),
              if (activity.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(activity.description, style: AppTextStyles.body),
              ],
              const SizedBox(height: 20),
              const Divider(color: AppColors.surfaceBorder),
              const SizedBox(height: 16),
              _row('Propietario', activity.ownerName),
              if (activity.assignedToName != null) _row('Asignada a', activity.assignedToName!),
              if (activity.assignedByName != null) _row('Asignada por', activity.assignedByName!),
              if (activity.projectName != null)    _row('Proyecto', activity.projectName!),
              if (activity.targetDate != null)     _row('Fecha objetivo', _fmt(activity.targetDate!)),
              if (activity.completedAt != null)    _row('Completada', _fmt(activity.completedAt!)),
              const SizedBox(height: 24),
              if (!activity.isCompleted)
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Marcar como completada'),
                ),
            ]),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      SizedBox(width: 130, child: Text(label, style: AppTextStyles.caption)),
      Expanded(child: Text(value, style: AppTextStyles.body)),
    ]),
  );

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}
