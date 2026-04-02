import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/projects_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../stats/providers/stats_provider.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/models/project.dart';
import '../../../shared/models/user.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/paleta_pasteles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/project_kind.dart';
import '../../../core/utils/projects_access.dart';

String _estadoProyectoLegible(String? status) {
  switch (status) {
    case 'active':
      return 'Activo';
    case 'paused':
    case 'on_hold':
      return 'En pausa';
    case 'completed':
    case 'done':
      return 'Completado';
    case 'cancelled':
      return 'Cancelado';
    default:
      return status?.isNotEmpty == true ? status! : 'Sin estado';
  }
}

enum _ProjectsTab { personal, team }

/// Listado de proyectos filtrado por rol: personales vs equipo / para AA.
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  _ProjectsTab _tab = _ProjectsTab.personal;

  Map<String, List<ActivityModel>> _actividadesPorProyecto(
    List<ProjectModel> proyectos,
    List<ActivityModel> todas,
  ) {
    return {
      for (final p in proyectos)
        p.id: todas.where((a) => a.projectId == p.id).toList(),
    };
  }

  List<ProjectModel> _projectsForTab(UserModel u, List<ProjectModel> all) {
    if (u.isPersonalAccount) {
      return personalProjectsOwnedBy(u, all);
    }
    if (u.isSuperAdmin) {
      return _tab == _ProjectsTab.personal
          ? personalProjectsOwnedBy(u, all)
          : saProjectsForAreaAdmins(all);
    }
    return _tab == _ProjectsTab.personal
        ? personalProjectsOwnedBy(u, all)
        : teamProjectsForArea(u, all);
  }

  bool _showTabBar(UserModel u) {
    if (u.isPersonalAccount) return false;
    return true;
  }

  Future<void> _mostrarDialogoCrearProyecto(BuildContext context) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final isSa = user.isSuperAdmin;
    List<Map<String, dynamic>> areasList = [];
    if (isSa) {
      try {
        areasList = await ref.read(allAreasStatsProvider.future);
      } catch (_) {}
    }

    if (!context.mounted) return;

    var areaIdForCreate = areasList.isNotEmpty
        ? areasList.first['area_id'] as String
        : '';
    var asignarAA = false;

    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final brightness = Theme.of(context).brightness;
    Color colorSeleccionado = PaletaPasteles.proyectoPredeterminado(brightness);

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuevo proyecto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.folder),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.description),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  maxLines: 3,
                ),
                if (isSa) ...[
                  const SizedBox(height: 16),
                  const Text('Tipo de proyecto'),
                  RadioListTile<bool>(
                    title: const Text('Personal (sin área)'),
                    subtitle: const Text('Solo visible en tus proyectos personales'),
                    value: false,
                    groupValue: asignarAA,
                    onChanged: (v) =>
                        setDialogState(() => asignarAA = v ?? false),
                  ),
                  RadioListTile<bool>(
                    title: const Text('Para un administrador de área'),
                    subtitle: const Text('Asignado a un equipo'),
                    value: true,
                    groupValue: asignarAA,
                    onChanged: (v) =>
                        setDialogState(() => asignarAA = v ?? false),
                  ),
                  if (asignarAA) ...[
                    const SizedBox(height: 8),
                    if (areasList.isEmpty)
                      Text(
                        'No hay áreas en el mock. Usa proyecto personal o configura áreas.',
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                          fontSize: 13,
                        ),
                      )
                    else
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Área y administrador *',
                          prefixIcon: Icon(Icons.groups_outlined),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: areaIdForCreate.isEmpty
                                ? areasList.first['area_id'] as String
                                : areaIdForCreate,
                            isExpanded: true,
                            items: areasList.map((row) {
                              final id = row['area_id'] as String;
                              final an = row['area_name'] as String? ?? '';
                              final adm = row['admin_name'] as String? ?? '';
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(
                                  '$an · $adm',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setDialogState(() => areaIdForCreate = v);
                            },
                          ),
                        ),
                      ),
                  ],
                ],
                const SizedBox(height: 16),
                Text(
                  'Color',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (ctx) {
                    final colores = PaletaPasteles.coloresProyecto(brightness);
                    Widget colorDot(Color color) {
                      final scheme = Theme.of(ctx).colorScheme;
                      final checkOnPastel = color.computeLuminance() > 0.55
                          ? const Color(0xFF2C2C2E)
                          : Colors.white;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => colorSeleccionado = color);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorSeleccionado == color
                                  ? scheme.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: colorSeleccionado == color
                              ? Icon(Icons.check, color: checkOnPastel, size: 20)
                              : null,
                        ),
                      );
                    }

                    final filaSuperior = colores.take(4).toList();
                    final filaInferior = colores.skip(4).toList();

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: filaSuperior
                              .map(
                                (c) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: colorDot(c),
                                ),
                              )
                              .toList(),
                        ),
                        if (filaInferior.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: filaInferior
                                .map(
                                  (c) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: colorDot(c),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (nombreController.text.trim().isNotEmpty) {
                  if (isSa && asignarAA && areasList.isEmpty) return;
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    final nombre = nombreController.text.trim();
    final desc = descripcionController.text.trim();
    nombreController.dispose();
    descripcionController.dispose();

    if (resultado != true || nombre.isEmpty) return;

    String? areaArg;
    if (isSa) {
      areaArg = asignarAA && areaIdForCreate.isNotEmpty ? areaIdForCreate : null;
    } else {
      areaArg = null;
    }

    try {
      await ref.read(projectRepositoryProvider).createProject(
            name: nombre,
            description: desc.isEmpty ? null : desc,
            color: PaletaPasteles.colorToHexRgb(colorSeleccionado),
            areaId: areaArg,
          );
      ref.invalidate(projectsProvider);
      ref.invalidate(allActivitiesProvider);
      ref.invalidate(dashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.exito('Proyecto creado exitosamente'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error al crear proyecto: $e'),
        );
      }
    }
  }

  Widget _tarjetaEquipo(
    BuildContext context,
    ProjectModel proyecto,
    List<ActivityModel> actividades,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final total = actividades.length;
    final completadas =
        actividades.where((a) => a.status == ActivityStatus.completada).length;
    final avance = total > 0 ? completadas / total : 0.0;
    final proyectoColor = PaletaPasteles.proyectoColorByMode(
      proyecto.color,
      Theme.of(context).brightness,
    );

    return Card(
      child: InkWell(
        onTap: () => context.go('/projects/${proyecto.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: proyectoColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.groups_outlined, color: proyectoColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proyecto.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (proyecto.description.isNotEmpty)
                          Text(
                            proyecto.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 17,
                                  height: 1.25,
                                  color: scheme.onSurfaceVariant,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.manage_accounts_outlined,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      proyecto.areaAdminName?.isNotEmpty == true
                          ? proyecto.areaAdminName!
                          : (proyecto.areaName ?? 'Área asignada'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _estadoProyectoLegible(proyecto.status),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (total == 0)
                Text(
                  'Sin actividades — el equipo aún no ha registrado tareas',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Avance',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${(avance * 100).round()}%',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: avance,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(proyectoColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaPersonal(
    BuildContext context,
    ProjectModel proyecto,
    List<ActivityModel> actividades, {
    required UserModel viewer,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final total = actividades.length;
    final completadas =
        actividades.where((a) => a.status == ActivityStatus.completada).length;
    final avance = total > 0 ? completadas / total : 0.0;
    final proyectoColor = PaletaPasteles.proyectoColorByMode(
      proyecto.color,
      Theme.of(context).brightness,
    );

    final porEstado = <ActivityStatus, int>{};
    for (final e in ActivityStatus.values) {
      porEstado[e] = actividades.where((a) => a.status == e).length;
    }

    final mostrarAsignatario =
        isTeamProject(proyecto) &&
            (viewer.isAdminArea || viewer.isTrabajador);

    return Card(
      child: InkWell(
        onTap: () => context.go('/projects/${proyecto.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: proyectoColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.folder_outlined, color: proyectoColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proyecto.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (proyecto.description.isNotEmpty)
                          Text(
                            proyecto.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 17,
                                  height: 1.25,
                                  color: scheme.onSurfaceVariant,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isTeamProject(proyecto)) ...[
                const SizedBox(height: 10),
                Text(
                  proyecto.areaName ?? proyecto.areaAdminName ?? 'Equipo',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Actividades por estado',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in ActivityStatus.values)
                    if ((porEstado[e] ?? 0) > 0)
                      Chip(
                        label: Text('${e.label}: ${porEstado[e]}'),
                        visualDensity: VisualDensity.compact,
                      ),
                ],
              ),
              if (mostrarAsignatario && actividades.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Asignación',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                ...actividades.take(5).map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${a.title} → ${a.assignedToName ?? a.ownerName}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                if (actividades.length > 5)
                  Text(
                    '… y ${actividades.length - 5} más',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
              ],
              const SizedBox(height: 16),
              if (total == 0)
                Text(
                  'Sin actividades en este proyecto',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Avance',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${(avance * 100).round()}%',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: avance,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(proyectoColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(
    BuildContext context,
    UserModel user,
    ProjectModel proyecto,
    List<ActivityModel> actividades,
  ) {
    if (user.isSuperAdmin && _tab == _ProjectsTab.team) {
      return _tarjetaEquipo(context, proyecto, actividades);
    }
    return _tarjetaPersonal(context, proyecto, actividades, viewer: user);
  }

  Widget _selectorTabs(BuildContext context, UserModel user) {
    final scheme = Theme.of(context).colorScheme;
    final isSa = user.isSuperAdmin;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SegmentedButton<_ProjectsTab>(
        segments: [
          ButtonSegment(
            value: _ProjectsTab.personal,
            label: const Text('Personales'),
            icon: const Icon(Icons.person_outline, size: 18),
          ),
          ButtonSegment(
            value: _ProjectsTab.team,
            label: Text(isSa ? 'Para AA' : 'Equipo'),
            icon: Icon(isSa ? Icons.admin_panel_settings_outlined : Icons.groups_outlined, size: 18),
          ),
        ],
        selected: {_tab},
        onSelectionChanged: (s) => setState(() => _tab = s.first),
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Future<void> _recargar() async {
    ref.invalidate(projectsProvider);
    ref.invalidate(allActivitiesProvider);
    await Future.wait([
      ref.read(projectsProvider.future),
      ref.read(allActivitiesProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final activitiesAsync = ref.watch(allActivitiesProvider);
    final isTablet = Responsive.isTablet(context);
    final columnCount = Responsive.getColumnCount(context);
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);

    final canCreateProject = user != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _recargar,
          ),
          if (canCreateProject)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _mostrarDialogoCrearProyecto(context),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_outlined,
                          size: 48, color: scheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'No se pudieron cargar los proyectos',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(projectsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (allProjects) {
                final visible = _projectsForTab(user, allProjects);

                if (visible.isEmpty) {
                  return Column(
                    children: [
                      if (_showTabBar(user)) _selectorTabs(context, user),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_outlined,
                                  size: 64, color: scheme.outline),
                              const SizedBox(height: 16),
                              Text(
                                _tab == _ProjectsTab.personal
                                    ? 'No hay proyectos personales'
                                    : (user.isSuperAdmin
                                        ? 'No hay proyectos para administradores'
                                        : 'No hay proyectos de equipo'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                              if (canCreateProject) ...[
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _mostrarDialogoCrearProyecto(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Crear proyecto'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final todas = activitiesAsync.valueOrNull ?? [];
                final porProyecto = _actividadesPorProyecto(visible, todas);

                return Column(
                  children: [
                    if (_showTabBar(user)) _selectorTabs(context, user),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _recargar,
                        child: isTablet
                            ? GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.all(
                                  Responsive.getHorizontalPadding(context),
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columnCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.05,
                                ),
                                itemCount: visible.length,
                                itemBuilder: (_, i) {
                                  final p = visible[i];
                                  return _tarjeta(
                                    context,
                                    user,
                                    p,
                                    porProyecto[p.id] ?? [],
                                  );
                                },
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.all(
                                  Responsive.getHorizontalPadding(context),
                                ),
                                itemCount: visible.length,
                                itemBuilder: (_, i) {
                                  final p = visible[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _tarjeta(
                                      context,
                                      user,
                                      p,
                                      porProyecto[p.id] ?? [],
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
