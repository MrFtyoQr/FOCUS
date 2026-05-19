import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/activity_card.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/models/project.dart';
import '../../projects/providers/projects_provider.dart';
import '../providers/dashboard_provider.dart';

/// Listado global de actividades con filtros por estado y rango de fechas (creación).
class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  ActivityStatus? _filtroEstado;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  List<ActivityModel> _filtrar(List<ActivityModel> todas) {
    var list = List<ActivityModel>.from(todas);

    if (_filtroEstado != null) {
      list = list.where((a) => a.status == _filtroEstado).toList();
    }

    if (_fechaDesde != null) {
      final start = DateTime(
        _fechaDesde!.year,
        _fechaDesde!.month,
        _fechaDesde!.day,
      );
      list = list.where((a) {
        final d = DateTime(a.createdAt.year, a.createdAt.month, a.createdAt.day);
        return !d.isBefore(start);
      }).toList();
    }

    if (_fechaHasta != null) {
      final end = DateTime(
        _fechaHasta!.year,
        _fechaHasta!.month,
        _fechaHasta!.day,
      );
      list = list.where((a) {
        final d = DateTime(a.createdAt.year, a.createdAt.month, a.createdAt.day);
        return !d.isAfter(end);
      }).toList();
    }

    return list;
  }

  Future<void> _recargar() async {
    ref.invalidate(allActivitiesProvider);
    ref.invalidate(projectsProvider);
    await ref.read(allActivitiesProvider.future);
  }

  Future<void> _seleccionarFechaDesde() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaDesde ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null && mounted) {
      setState(() => _fechaDesde = fecha);
    }
  }

  Future<void> _seleccionarFechaHasta() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaHasta ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null && mounted) {
      setState(() => _fechaHasta = fecha);
    }
  }

  Map<String, String> _coloresPorProyecto(List<ProjectModel> proyectos) {
    return {for (final p in proyectos) p.id: p.color};
  }

  void _mostrarFiltros() {
    final isTablet = Responsive.isTablet(context);
    final wide = MediaQuery.of(context).size.width > 700;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtros',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      'Estado',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (isTablet && wide)
                      SegmentedButton<ActivityStatus?>(
                        segments: [
                          const ButtonSegment<ActivityStatus?>(
                            value: null,
                            label: Text('Todos'),
                          ),
                          ...ActivityStatus.values.map(
                            (e) => ButtonSegment<ActivityStatus?>(
                              value: e,
                              label: Text(e.label),
                            ),
                          ),
                        ],
                        selected: {_filtroEstado},
                        onSelectionChanged: (s) {
                          setState(() => _filtroEstado = s.first);
                          Navigator.pop(ctx);
                        },
                      )
                    else
                      SizedBox(
                        height: 52,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: ActivityStatus.values.length + 1,
                          itemBuilder: (_, index) {
                            final ActivityStatus? estado;
                            if (index == 0) {
                              estado = null;
                            } else {
                              estado = ActivityStatus.values[index - 1];
                            }
                            final isSelected = estado == _filtroEstado;
                            final scheme = Theme.of(context).colorScheme;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                selected: isSelected,
                                label: Text(estado == null ? 'Todos' : estado.label),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _filtroEstado = estado);
                                    Navigator.pop(ctx);
                                  }
                                },
                                selectedColor: scheme.primaryContainer,
                                checkmarkColor: scheme.onPrimaryContainer,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? scheme.onPrimaryContainer
                                      : scheme.onSurface,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Fechas (creación)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _seleccionarFechaDesde();
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _fechaDesde != null
                                  ? '${_fechaDesde!.day}/${_fechaDesde!.month}/${_fechaDesde!.year}'
                                  : 'Desde',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _seleccionarFechaHasta();
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _fechaHasta != null
                                  ? '${_fechaHasta!.day}/${_fechaHasta!.month}/${_fechaHasta!.year}'
                                  : 'Hasta',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _filtroEstado = null;
                          _fechaDesde = null;
                          _fechaHasta = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Limpiar filtros'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actividadesAsync = ref.watch(allActivitiesProvider);
    final proyectos = ref.watch(projectsProvider).valueOrNull ?? [];
    final colores = _coloresPorProyecto(proyectos);
    final scheme = Theme.of(context).colorScheme;
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
        ],
      ),
      body: actividadesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 16),
                Text('Error al cargar: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _recargar,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (todas) {
          final filtradas = _filtrar(todas);
          final hayFiltros =
              _filtroEstado != null || _fechaDesde != null || _fechaHasta != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hayFiltros)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: scheme.surfaceContainerHighest,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_filtroEstado != null)
                        Chip(
                          label: Text(_filtroEstado!.label),
                          onDeleted: () => setState(() => _filtroEstado = null),
                        ),
                      if (_fechaDesde != null)
                        Chip(
                          label: Text(
                            'Desde: ${_fechaDesde!.day}/${_fechaDesde!.month}/${_fechaDesde!.year}',
                          ),
                          onDeleted: () => setState(() => _fechaDesde = null),
                        ),
                      if (_fechaHasta != null)
                        Chip(
                          label: Text(
                            'Hasta: ${_fechaHasta!.day}/${_fechaHasta!.month}/${_fechaHasta!.year}',
                          ),
                          onDeleted: () => setState(() => _fechaHasta = null),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: filtradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: scheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No hay actividades',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _recargar,
                        child: isTablet
                            ? GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.all(
                                  Responsive.getHorizontalPadding(context),
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      Responsive.getColumnCount(context),
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.2,
                                ),
                                itemCount: filtradas.length,
                                itemBuilder: (_, i) {
                                  final a = filtradas[i];
                                  final hex = a.projectId != null
                                      ? colores[a.projectId]
                                      : null;
                                  return ActivityCard(
                                    activity: a,
                                    projectColorHex: hex,
                                    onTap: () =>
                                        context.go('/activity/${a.id}'),
                                    onComplete: () async {
                                      try {
                                        await ref
                                            .read(activityRepositoryProvider)
                                            .completeActivity(a.id);
                                        ref.invalidate(allActivitiesProvider);
                                        ref.invalidate(dashboardProvider);
                                        ref.invalidate(projectsProvider);
                                        if (mounted) setState(() {});
                                      } catch (err) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          AppSnackBar.error('$err'),
                                        );
                                      }
                                    },
                                  );
                                },
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.all(
                                  Responsive.getHorizontalPadding(context),
                                ),
                                itemCount: filtradas.length,
                                itemBuilder: (_, i) {
                                  final a = filtradas[i];
                                  final hex = a.projectId != null
                                      ? colores[a.projectId]
                                      : null;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ActivityCard(
                                      activity: a,
                                      projectColorHex: hex,
                                      onTap: () =>
                                          context.go('/activity/${a.id}'),
                                      onComplete: () async {
                                        try {
                                          await ref
                                              .read(activityRepositoryProvider)
                                              .completeActivity(a.id);
                                          ref.invalidate(allActivitiesProvider);
                                          ref.invalidate(dashboardProvider);
                                          ref.invalidate(projectsProvider);
                                          if (mounted) setState(() {});
                                        } catch (err) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            AppSnackBar.error('$err'),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
