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
    final myStatsAsync = ref.watch(myStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productividad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(myStatsProvider),
          ),
        ],
      ),
      body: myStatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No se pudieron cargar las estadísticas'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(myStatsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (stats) => stats.isEmpty
            ? const EmptyState(
                icon: Icons.bar_chart_outlined,
                title: 'Sin datos',
                subtitle: 'Completa actividades para ver tus estadísticas.',
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen personal',
                        style: AppTextStyles.heading2),
                    const SizedBox(height: 16),
                    _StatsGrid(stats: stats),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = stats.entries
        .where((e) => e.value is num)
        .toList();

    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'Sin métricas',
        subtitle: 'El servidor aún no reporta estadísticas.',
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final key   = entries[i].key;
        final value = entries[i].value;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.toString(),
                style: AppTextStyles.heading1.copyWith(
                    color: AppColors.purple),
              ),
              const SizedBox(height: 4),
              Text(
                _formatKey(key),
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
