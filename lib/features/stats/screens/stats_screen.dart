import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Productividad')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: e.toString()),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mi rendimiento', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Row(children: [
              _StatCard(label: 'Completadas', value: '${stats['completed'] ?? 0}', color: AppColors.teal),
              const SizedBox(width: 12),
              _StatCard(label: 'Pendientes', value: '${stats['pending'] ?? 0}', color: AppColors.amber),
              const SizedBox(width: 12),
              _StatCard(label: 'Vencidas', value: '${stats['overdue'] ?? 0}', color: AppColors.red),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceBorder, width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tasa de completado', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ((stats['completion_rate'] as num?) ?? 0) / 100,
                      minHeight: 10,
                      backgroundColor: AppColors.surfaceBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Text('${((stats['completion_rate'] as num?) ?? 0).toStringAsFixed(1)}%',
                    style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700, fontSize: 16)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ]),
    ),
  );
}
