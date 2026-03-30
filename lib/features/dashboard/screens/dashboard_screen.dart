import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/widgets/activity_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/enums/activity_status.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tablero'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(dashboardProvider)),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => context.go('/profile')),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: e.toString()),
        data: (grouped) {
          final columns = ActivityStatus.values.where((s) => s != ActivityStatus.completada).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: columns.length,
            itemBuilder: (_, i) {
              final status   = columns[i];
              final items    = grouped[status] ?? [];
              final color    = AppColors.statusColor(status.name);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    Text(status.label, style: AppTextStyles.heading2),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: Text('${items.length}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Sin actividades', style: AppTextStyles.caption),
                    )
                  else
                    ...items.map((a) => ActivityCard(
                      activity: a,
                      onTap: () => context.go('/activity/${a.id}'),
                    )),
                  const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
