import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/team_provider.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../shared/enums/user_role.dart';
import '../../../core/utils/activity_scope.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/models/project.dart';
import '../../../core/widgets/activity_card.dart';
import '../../../core/widgets/mover_actividad_bottom_sheet.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/responsive.dart';

/// Tablero con estados Bandeja → Pendientes y lista/grid de actividades.
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

  String _descripcionEstado(ActivityStatus s) {
    return switch (s) {
      ActivityStatus.bandeja =>
        'Ideas y tareas sin priorizar; revísalas para pasarlas a Hoy.',
      ActivityStatus.hoy => 'Lo que trabajas hoy. Mantén la lista realista.',
      ActivityStatus.manana =>
        'Preparado para mañana; al llegar el día pásalo a Hoy.',
      ActivityStatus.programado =>
        'Con fecha objetivo. Revisa el calendario con antelación.',
      ActivityStatus.pendientes =>
        'En pausa o bloqueado; desbloquea cuando puedas avanzar.',
      ActivityStatus.completada => 'Hecho.',
    };
  }

  IconData _iconoEstado(ActivityStatus estado) {
    return switch (estado) {
      ActivityStatus.bandeja => Icons.inbox_outlined,
      ActivityStatus.hoy => Icons.today_outlined,
      ActivityStatus.manana => Icons.event_outlined,
      ActivityStatus.programado => Icons.schedule_outlined,
      ActivityStatus.pendientes => Icons.pause_circle_outline,
      ActivityStatus.completada => Icons.star_outline,
    };
  }

  Map<String, String> _coloresProyecto(List<ProjectModel> proyectos) {
    return {for (final p in proyectos) p.id: p.color};
  }

  Future<void> _refrescar() async {
    ref.invalidate(dashboardProvider);
    ref.invalidate(allActivitiesProvider);
    ref.invalidate(projectsProvider);
    await Future.wait([
      ref.read(dashboardProvider.future),
      ref.read(allActivitiesProvider.future),
    ]);
  }

  void _invalidarTablero() {
    ref.invalidate(dashboardProvider);
    ref.invalidate(allActivitiesProvider);
  }

  void _onAmbitoChanged(ActivityDashboardScope s) {
    ref.read(dashboardScopeUiProvider.notifier).state = s;
  }

  Future<void> _completarActividad(ActivityModel actividad) async {
    final prev = actividad.status;
    final repo = ref.read(activityRepositoryProvider);
    try {
      await repo.completeActivity(actividad.id);
      _invalidarTablero();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.exito(
          '${actividad.title} completada',
          etiquetaAccion: 'Deshacer',
          alAccion: () async {
            try {
              await repo.moveActivity(actividad.id, prev.apiValue);
              _invalidarTablero();
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                AppSnackBar.error('No se pudo deshacer: $e'),
              );
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error: $e'),
        );
      }
    }
  }

  void _mostrarMover(ActivityModel actividad) {
    mostrarMoverActividadBottomSheet(
      context,
      actividad,
      (nuevoEstado) => _moverActividad(actividad, nuevoEstado),
    );
  }

  Future<void> _moverActividad(
    ActivityModel actividad,
    ActivityStatus nuevoEstado,
  ) async {
    if (nuevoEstado == ActivityStatus.programado &&
        actividad.targetDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.aviso(
            'Las actividades programadas requieren una fecha objetivo',
          ),
        );
      }
      return;
    }

    final estadoAnterior = actividad.status;
    final repo = ref.read(activityRepositoryProvider);
    try {
      await repo.moveActivity(actividad.id, nuevoEstado.apiValue);
      _invalidarTablero();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.exito(
          'Movida a ${nuevoEstado.label}',
          etiquetaAccion: 'Deshacer',
          alAccion: () async {
            try {
              await repo.moveActivity(actividad.id, estadoAnterior.apiValue);
              _invalidarTablero();
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                AppSnackBar.error('No se pudo deshacer: $e'),
              );
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error al mover: $e'),
        );
      }
    }
  }

  void _onEstadoChanged(ActivityStatus nuevo) {
    setState(() => _selected = nuevo);
  }

  Widget _filtroAmbitoTablero(BuildContext context, UserRole role) {
    final isSa = role == UserRole.superAdmin;
    final isOrgRole = role == UserRole.adminArea || role == UserRole.trabajador;
    if (!isSa && !isOrgRole) return const SizedBox.shrink();

    final scope = ref.watch(dashboardScopeUiProvider);
    final scheme = Theme.of(context).colorScheme;

    // Normaliza el scope al conjunto válido según rol para evitar assertion errors.
    final safeScope = isSa
        ? (scope == ActivityDashboardScope.team
            ? ActivityDashboardScope.all
            : scope)
        : (scope == ActivityDashboardScope.assigned
            ? ActivityDashboardScope.all
            : scope);

    final segments = isSa
        ? const <ButtonSegment<ActivityDashboardScope>>[
            ButtonSegment(
              value: ActivityDashboardScope.all,
              label: Text('Todas'),
              icon: Icon(Icons.layers_outlined, size: 18),
            ),
            ButtonSegment(
              value: ActivityDashboardScope.personal,
              label: Text('Personales'),
              icon: Icon(Icons.person_outline, size: 18),
            ),
            ButtonSegment(
              value: ActivityDashboardScope.assigned,
              label: Text('Asignadas'),
              icon: Icon(Icons.assignment_ind_outlined, size: 18),
            ),
          ]
        : const <ButtonSegment<ActivityDashboardScope>>[
            ButtonSegment(
              value: ActivityDashboardScope.all,
              label: Text('Todas'),
              icon: Icon(Icons.layers_outlined, size: 18),
            ),
            ButtonSegment(
              value: ActivityDashboardScope.personal,
              label: Text('Personales'),
              icon: Icon(Icons.person_outline, size: 18),
            ),
            ButtonSegment(
              value: ActivityDashboardScope.team,
              label: Text('Equipo'),
              icon: Icon(Icons.groups_outlined, size: 18),
            ),
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SegmentedButton<ActivityDashboardScope>(
        segments: segments,
        selected: {safeScope},
        onSelectionChanged: (s) => _onAmbitoChanged(s.first),
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _selectorEstados(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isTablet = Responsive.isTablet(context);
    final wide = MediaQuery.of(context).size.width > 700;

    if (isTablet && wide) {
      return Padding(
        padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
        child: SegmentedButton<ActivityStatus>(
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            shape: const StadiumBorder(),
          ),
          segments: [
            for (final estado in _tabs)
              ButtonSegment<ActivityStatus>(
                value: estado,
                label: Text(estado.label),
              ),
          ],
          selected: {_selected},
          onSelectionChanged: (s) => _onEstadoChanged(s.first),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _tabs.length,
        itemBuilder: (_, index) {
          final estado = _tabs[index];
          final isSelected = estado == _selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              shape: const StadiumBorder(),
              label: Text(
                estado.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              onSelected: (selected) {
                if (selected) _onEstadoChanged(estado);
              },
              selectedColor: scheme.primaryContainer,
              checkmarkColor: scheme.onPrimaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurface,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _listaActividades(
    BuildContext context,
    List<ActivityModel> list,
    Map<String, String> colorPorProyecto,
    List<ProjectModel> proyectos,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final members = ref.watch(teamMembersProvider).valueOrNull ?? [];
    final me = ref.watch(currentUserProvider);
    final userNames = <String, String>{
      for (final u in members)
        u.id: u.fullName.trim().isNotEmpty ? u.fullName.trim() : u.email,
      if (me != null)
        me.id: me.fullName.trim().isNotEmpty ? me.fullName.trim() : me.email,
    };
    final projectById = {for (final p in proyectos) p.id: p};
    final enriched = list
        .map(
          (a) => a.copyWith(
            projectName: a.projectName ?? projectById[a.projectId]?.name,
            assignedToName: a.assignedToName ??
                (a.assignedToId != null
                    ? userNames[a.assignedToId!]
                    : null),
            assignedByName: a.assignedByName ??
                (a.assignedById != null
                    ? userNames[a.assignedById!]
                    : null),
          ),
        )
        .toList();

    if (enriched.isEmpty) {
      return Center(
        key: ValueKey('empty_${_selected.name}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _iconoEstado(_selected),
                size: 64,
                color: scheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay actividades en ${_selected.label}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _descripcionEstado(_selected),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final isTablet = Responsive.isTablet(context);
    final columnCount = Responsive.getColumnCount(context);
    final pad = Responsive.getHorizontalPadding(context);

    Widget tarjeta(ActivityModel a) {
      final hex = a.projectId != null ? colorPorProyecto[a.projectId] : null;
      return ActivityCard(
        activity: a,
        projectColorHex: hex,
        onTap: () => context.go('/activity/${a.id}'),
        onComplete: () => _completarActividad(a),
        onMove: () => _mostrarMover(a),
      );
    }

    return RefreshIndicator(
      onRefresh: _refrescar,
      child: isTablet
          ? GridView.builder(
              key: ValueKey('grid_${_selected.name}_${enriched.length}'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(pad),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.92,
              ),
              itemCount: enriched.length,
              itemBuilder: (_, i) => tarjeta(enriched[i]),
            )
          : ListView.builder(
              key: ValueKey('list_${_selected.name}_${enriched.length}'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: enriched.length,
              itemBuilder: (_, i) => tarjeta(enriched[i]),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(dashboardProvider);
    final proyectos = ref.watch(projectsProvider).valueOrNull ?? [];
    final colorPorProyecto = _coloresProyecto(proyectos);
    final role = user?.role ?? UserRole.trabajador;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Historial',
            onPressed: () => context.go('/historial'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refrescar,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          _filtroAmbitoTablero(context, role),
          _selectorEstados(context),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: dashAsync.when(
                loading: () => const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(),
                ),
                error: (err, _) => Center(
                  key: const ValueKey('error'),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se pudo cargar el tablero',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Verifica tu conexión y que el servidor esté disponible.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
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
                  return _listaActividades(
                    context,
                    list,
                    colorPorProyecto,
                    proyectos,
                  );
                },
              ),
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
