import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../core/theme/app_colors.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final String id;
  const ActivityDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actAsync = ref.watch(
      FutureProvider<ActivityModel>((ref) =>
          ref.read(activityRepositoryProvider).getActivity(id)).future,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: FutureBuilder<ActivityModel>(
        future: actAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No se pudo cargar la actividad'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          final activity = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título + estado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusChip(status: activity.status),
                  ],
                ),
                if (activity.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    activity.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                // Metadatos
                _InfoRow(label: 'Creada por', value: activity.ownerName),
                if (activity.assignedToName != null)
                  _InfoRow(
                      label: 'Asignada a', value: activity.assignedToName!),
                if (activity.projectName != null)
                  _InfoRow(label: 'Proyecto', value: activity.projectName!),
                if (activity.areaName != null)
                  _InfoRow(label: 'Área', value: activity.areaName!),
                if (activity.targetDate != null)
                  _InfoRow(
                    label: 'Fecha objetivo',
                    value:
                        '${activity.targetDate!.day.toString().padLeft(2, '0')}/'
                        '${activity.targetDate!.month.toString().padLeft(2, '0')}/'
                        '${activity.targetDate!.year}',
                  ),
                if (activity.completedAt != null)
                  _InfoRow(
                    label: 'Completada',
                    value:
                        '${activity.completedAt!.day.toString().padLeft(2, '0')}/'
                        '${activity.completedAt!.month.toString().padLeft(2, '0')}/'
                        '${activity.completedAt!.year}',
                  ),
                const SizedBox(height: 32),
                // Acciones
                if (!activity.isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(activityRepositoryProvider)
                            .completeActivity(id);
                        ref.invalidate(dashboardProvider);
                        if (context.mounted) context.go('/');
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Marcar como completada'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ActivityStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
