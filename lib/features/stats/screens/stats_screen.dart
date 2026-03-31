import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/enums/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return switch (user.role) {
      UserRole.superAdmin  => const _SuperAdminStats(),
      UserRole.adminArea   => const _AdminAreaStats(),
      UserRole.trabajador  => const _WorkerStats(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRABAJADOR — stats personales
// ─────────────────────────────────────────────────────────────────────────────
class _WorkerStats extends ConsumerWidget {
  const _WorkerStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi productividad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(myStatsProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorRetry(onRetry: () => ref.invalidate(myStatsProvider)),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador circular de tasa
              Center(
                child: _RingKpi(
                  rate: (stats['completion_rate'] as num).toDouble(),
                  label: 'Tasa de completado',
                ),
              ),
              const SizedBox(height: 24),
              // Cards de conteo
              _KpiCardGrid(items: [
                _KpiItem('Total', stats['total'], AppColors.purple),
                _KpiItem('Completadas', stats['completed'], AppColors.green),
                _KpiItem('Pendientes', stats['pending'], AppColors.amber),
                _KpiItem('Vencidas', stats['overdue'], AppColors.red),
              ]),
              const SizedBox(height: 24),
              _SectionTitle('Detalle'),
              _InfoRow(
                icon: Icons.timer_outlined,
                label: 'Promedio de completado',
                value: '${stats['avg_completion_days']} días',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN ÁREA — vista de su equipo
// ─────────────────────────────────────────────────────────────────────────────
class _AdminAreaStats extends ConsumerWidget {
  const _AdminAreaStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user        = ref.watch(currentUserProvider);
    final areaId      = user?.areaId ?? '';
    final areaAsync   = ref.watch(areaStatsProvider(areaId));
    final workerAsync = ref.watch(workerStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KPIs del área'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(areaStatsProvider);
              ref.invalidate(workerStatsProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Resumen del área ──────────────────────────────────────────
            areaAsync.when(
              loading: () => const _LoadingCard(),
              error: (_, __) => const SizedBox.shrink(),
              data: (area) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(area['area_name'] as String? ?? 'Mi área'),
                  const SizedBox(height: 12),
                  Center(
                    child: _RingKpi(
                      rate: (area['completion_rate'] as num).toDouble(),
                      label: 'Completado del área',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _KpiCardGrid(items: [
                    _KpiItem('Total', area['total'], AppColors.purple),
                    _KpiItem('Completadas', area['completed'], AppColors.green),
                    _KpiItem('Pendientes', area['pending'], AppColors.amber),
                    _KpiItem('Vencidas', area['overdue'], AppColors.red),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Por trabajador ────────────────────────────────────────────
            _SectionTitle('Rendimiento del equipo'),
            const SizedBox(height: 12),
            workerAsync.when(
              loading: () => const _LoadingCard(),
              error: (_, __) => const SizedBox.shrink(),
              data: (workers) => Column(
                children: workers
                    .map((w) => _WorkerBar(worker: w))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPER ADMIN — todas las áreas + drill-down
// ─────────────────────────────────────────────────────────────────────────────
class _SuperAdminStats extends ConsumerWidget {
  const _SuperAdminStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allAreasStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KPIs globales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(allAreasStatsProvider),
          ),
        ],
      ),
      body: allAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            _ErrorRetry(onRetry: () => ref.invalidate(allAreasStatsProvider)),
        data: (areas) {
          // Totales globales
          final totalAll     = areas.fold<int>(0, (s, a) => s + (a['total'] as int));
          final completedAll = areas.fold<int>(0, (s, a) => s + (a['completed'] as int));
          final overdueAll   = areas.fold<int>(0, (s, a) => s + (a['overdue'] as int));
          final globalRate   = totalAll == 0 ? 0.0 : completedAll / totalAll * 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Global ──────────────────────────────────────────────
                _SectionTitle('Resumen global'),
                const SizedBox(height: 12),
                Center(
                  child: _RingKpi(
                    rate: globalRate,
                    label: 'Completado global',
                  ),
                ),
                const SizedBox(height: 16),
                _KpiCardGrid(items: [
                  _KpiItem('Total', totalAll, AppColors.purple),
                  _KpiItem('Completadas', completedAll, AppColors.green),
                  _KpiItem('Vencidas', overdueAll, AppColors.red),
                  _KpiItem('Áreas', areas.length, AppColors.blue),
                ]),
                const SizedBox(height: 28),

                // ── Por área ─────────────────────────────────────────────
                _SectionTitle('Por área — toca para desglosar'),
                const SizedBox(height: 12),
                ...areas.map((area) => _AreaCard(
                      area: area,
                      onTap: () => _showAreaDetail(context, area),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAreaDetail(BuildContext context, Map<String, dynamic> area) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AreaDetailSheet(area: area),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets compartidos
// ─────────────────────────────────────────────────────────────────────────────

/// Indicador circular de tasa de completado
class _RingKpi extends StatelessWidget {
  final double rate;
  final String label;
  const _RingKpi({required this.rate, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = rate >= 80
        ? AppColors.green
        : rate >= 60
            ? AppColors.amber
            : AppColors.red;

    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140, height: 140,
                child: CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 12,
                  backgroundColor: AppColors.surfaceBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${rate.toStringAsFixed(1)}%',
                    style: AppTextStyles.heading1.copyWith(
                      color: color, fontSize: 26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.bodySecondary),
      ],
    );
  }
}

class _KpiItem {
  final String label;
  final dynamic value;
  final Color color;
  const _KpiItem(this.label, this.value, this.color);
}

/// Grid de tarjetas KPI (2 columnas)
class _KpiCardGrid extends StatelessWidget {
  final List<_KpiItem> items;
  const _KpiCardGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: item.color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${item.value}',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(item.label, style: AppTextStyles.caption),
            ],
          ),
        );
      },
    );
  }
}

/// Barra de progreso de un trabajador
class _WorkerBar extends StatelessWidget {
  final Map<String, dynamic> worker;
  const _WorkerBar({required this.worker});

  @override
  Widget build(BuildContext context) {
    final rate  = (worker['completion_rate'] as num).toDouble();
    final color = rate >= 80
        ? AppColors.green
        : rate >= 60 ? AppColors.amber : AppColors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(worker['name'] as String,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: AppColors.surfaceBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniStat(
                  label: 'Total', value: worker['total'], color: AppColors.purple),
              const SizedBox(width: 12),
              _MiniStat(
                  label: 'Completadas', value: worker['completed'], color: AppColors.green),
              const SizedBox(width: 12),
              _MiniStat(
                  label: 'Vencidas', value: worker['overdue'], color: AppColors.red),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.caption,
        children: [
          TextSpan(
            text: '$value ',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          TextSpan(text: label),
        ],
      ),
    );
  }
}

/// Tarjeta de área para la vista SuperAdmin
class _AreaCard extends StatelessWidget {
  final Map<String, dynamic> area;
  final VoidCallback onTap;
  const _AreaCard({required this.area, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rate  = (area['completion_rate'] as num).toDouble();
    final color = rate >= 80
        ? AppColors.green
        : rate >= 60 ? AppColors.amber : AppColors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(area['area_name'] as String,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'Admin: ${area['admin_name']}  •  ${area['members']} miembros',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${rate.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                    const SizedBox(height: 2),
                    Icon(Icons.chevron_right,
                        color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate / 100,
                minHeight: 7,
                backgroundColor: AppColors.surfaceBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MiniStat(
                    label: 'Total', value: area['total'], color: AppColors.purple),
                const SizedBox(width: 12),
                _MiniStat(
                    label: 'Completadas', value: area['completed'], color: AppColors.green),
                const SizedBox(width: 12),
                _MiniStat(
                    label: 'Vencidas', value: area['overdue'], color: AppColors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet con detalle del área (para SuperAdmin drill-down)
class _AreaDetailSheet extends StatelessWidget {
  final Map<String, dynamic> area;
  const _AreaDetailSheet({required this.area});

  @override
  Widget build(BuildContext context) {
    final rate = (area['completion_rate'] as num).toDouble();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(area['area_name'] as String,
              style: AppTextStyles.heading2),
          Text(
            'Admin: ${area['admin_name']}  •  ${area['members']} miembros',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 20),
          Center(
            child: _RingKpi(rate: rate, label: 'Completado del área'),
          ),
          const SizedBox(height: 20),
          _KpiCardGrid(items: [
            _KpiItem('Total', area['total'], AppColors.purple),
            _KpiItem('Completadas', area['completed'], AppColors.green),
            _KpiItem('Vencidas', area['overdue'], AppColors.red),
            _KpiItem('Miembros', area['members'], AppColors.blue),
          ]),
          const SizedBox(height: 16),
          // Pendiente: cuando el backend tenga el endpoint de workers por área
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El desglose por trabajador de esta área estará disponible cuando el backend exponga el endpoint correspondiente.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de UI
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: AppTextStyles.heading2);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.purple),
        title: Text(label, style: AppTextStyles.caption
            .copyWith(color: AppColors.textSecondary)),
        subtitle: Text(value, style: AppTextStyles.body),
        contentPadding: EdgeInsets.zero,
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No se pudieron cargar las estadísticas'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
}
