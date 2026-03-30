import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../core/widgets/activity_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/responsive.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  ActivityStatus _selected = ActivityStatus.bandeja;

  static const _tabs = [
    ActivityStatus.bandeja,
    ActivityStatus.hoy,
    ActivityStatus.manana,
    ActivityStatus.programado,
    ActivityStatus.pendientes,
  ];

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(dashboardProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(dashboardProvider),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented control de estados
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _tabs.length,
              itemBuilder: (_, i) {
                final tab      = _tabs[i];
                final selected = tab == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Lista de actividades
          Expanded(
            child: dashAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_outlined,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No se pudo cargar el tablero',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Verifica tu conexión y que el servidor esté disponible.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(dashboardProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (map) {
                final list = map[_selected] ?? [];
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Sin actividades',
                    subtitle: 'No hay actividades en "${_selected.label}".',
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: 8,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => ActivityCard(
                    activity: list[i],
                    onTap: () =>
                        context.go('/activity/${list[i].id}'),
                    onComplete: () async {
                      await ref
                          .read(activityRepositoryProvider)
                          .completeActivity(list[i].id);
                      ref.invalidate(dashboardProvider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/capture'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
