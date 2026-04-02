import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../providers/team_provider.dart';
import '../../../shared/enums/user_role.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/models/user.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/activity_status_colors.dart';
import '../../../core/utils/paleta_pasteles.dart';
import '../../../core/utils/responsive.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  Future<void> _refresh({required bool isSuperAdmin}) async {
    ref.invalidate(teamScreenDataProvider);
    ref.invalidate(teamScreenSaDataProvider);
    ref.invalidate(projectsProvider);
    ref.invalidate(allActivitiesProvider);
    if (isSuperAdmin) {
      await ref.read(teamScreenSaDataProvider.future);
    } else {
      await ref.read(teamScreenDataProvider.future);
    }
  }

  void _mostrarInviteInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.info(
        'Los miembros se añaden desde tu administración o enlace de invitación.',
      ),
    );
  }

  void _mostrarCrearAdminArea() {
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.info(
        'Aquí podrás crear perfiles de administrador de área cuando el flujo esté conectado al servidor.',
      ),
    );
  }

  Future<void> _invitarTrabajadorArea() async {
    final user = ref.read(currentUserProvider);
    final aid = user?.areaId;
    if (aid == null || !mounted) return;
    try {
      final map = await ref.read(teamRepositoryProvider).generateInvite(
            areaId: aid,
            role: 'trabajador',
          );
      final token = map['token'] as String? ?? '';
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invitar trabajador (TA)'),
          content: SelectableText(
            'Comparte el enlace de invitación con tu nuevo integrante:\n\n/invite/$token',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('No se pudo generar la invitación: $e'),
        );
      }
    }
  }

  Map<ActivityStatus, int> _contarPorEstado(List<ActivityModel> actividades) {
    final contador = <ActivityStatus, int>{};
    for (final e in ActivityStatus.values) {
      contador[e] = actividades.where((a) => a.status == e).length;
    }
    return contador;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isTablet = Responsive.isTablet(context);
    final columnCount = Responsive.getColumnCount(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user.role == UserRole.personal) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Equipo'),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, size: 72, color: muted),
                const SizedBox(height: 20),
                Text(
                  'Crea o únete a un equipo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Con una cuenta organizacional puedes ser Super Admin, invitar administradores de área o unirte con un enlace de invitación.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: muted,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () {
                    context.go('/invite/demo-organizacion');
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Abrir flujo de invitación (demo)'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _mostrarCrearAdminArea,
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: const Text('Saber más sobre ser Super Admin'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isSuperAdmin = user.isSuperAdmin;
    if (isSuperAdmin) {
      final async = ref.watch(teamScreenSaDataProvider);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Equipo'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Crear administrador de área',
              onPressed: _mostrarCrearAdminArea,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualizar',
              onPressed: () => _refresh(isSuperAdmin: true),
            ),
          ],
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildError(context, e, muted, () => _refresh(isSuperAdmin: true)),
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: muted),
                    const SizedBox(height: 16),
                    Text(
                      'No hay administradores de área',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: muted,
                          ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _mostrarCrearAdminArea,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear administrador de área'),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => _refresh(isSuperAdmin: true),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(
                  Responsive.getHorizontalPadding(context),
                ),
                itemCount: items.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Ordenados por mejor avance promedio en proyectos del área.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildSaAdminCard(context, items[i - 1]),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    final async = ref.watch(teamScreenDataProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipo'),
        elevation: 0,
        actions: [
          if (user.isAdminArea)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Invitar trabajador al área',
              onPressed: _invitarTrabajadorArea,
            ),
          if (!user.isTrabajador)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Invitar',
              onPressed: _mostrarInviteInfo,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () => _refresh(isSuperAdmin: false),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, e, muted, () => _refresh(isSuperAdmin: false)),
        data: (data) {
          final aid = user.areaId;
          var miembros = data.members;
          if (user.isAdminArea && aid != null) {
            miembros = data.members
                .where(
                  (m) => m.areaId == aid && m.isTrabajador && m.id != user.id,
                )
                .toList();
          } else if (user.isTrabajador && aid != null) {
            miembros = data.members
                .where(
                  (m) =>
                      m.areaId == aid &&
                      (m.isAdminArea ||
                          (m.isTrabajador && m.id != user.id)),
                )
                .toList();
          }

          if (miembros.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: muted),
                  const SizedBox(height: 16),
                  Text(
                    'No hay personas en el equipo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: muted,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (user.isAdminArea)
                    FilledButton.icon(
                      onPressed: _invitarTrabajadorArea,
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Añadir trabajador'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _mostrarInviteInfo,
                      icon: const Icon(Icons.add),
                      label: const Text('Invitar al equipo'),
                    ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refresh(isSuperAdmin: false),
            child: isTablet
                ? GridView.builder(
                    padding: EdgeInsets.all(
                      Responsive.getHorizontalPadding(context),
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: miembros.length,
                    itemBuilder: (_, i) => _buildPersonaCard(
                      context,
                      miembros[i],
                      data.activitiesFor(miembros[i].id),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(
                      Responsive.getHorizontalPadding(context),
                    ),
                    itemCount: miembros.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPersonaCard(
                        context,
                        miembros[i],
                        data.activitiesFor(miembros[i].id),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    Object e,
    Color muted,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: muted),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el equipo',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$e',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: muted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaAdminCard(BuildContext context, SaTeamAdminCardData data) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final aa = data.admin;
    final muted = scheme.onSurfaceVariant;
    final initial = aa.firstName.isNotEmpty
        ? aa.firstName[0].toUpperCase()
        : '?';

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedShape: const RoundedRectangleBorder(),
          shape: const RoundedRectangleBorder(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          leading: CircleAvatar(
            backgroundColor: scheme.primary.withValues(alpha: 0.18),
            child: Text(
              initial,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            aa.fullName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                aa.email,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: 6),
              Text(
                '${aa.areaName ?? 'Sin área'} · ${aa.role.label}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${data.projects.length} ${data.projects.length == 1 ? 'proyecto' : 'proyectos'} · '
                '${data.trabajadores.length} TA',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: 4),
              Text(
                'Toca para ver proyectos y equipo',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
            ],
          ),
          children: [
            Divider(height: 1, color: scheme.outlineVariant),
            ..._saSeccionProyectos(context, data),
            ..._saSeccionTrabajadores(context, data),
          ],
        ),
      ),
    );
  }

  List<Widget> _saSeccionProyectos(
    BuildContext context,
    SaTeamAdminCardData data,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final brightness = theme.brightness;
    final out = <Widget>[
      const SizedBox(height: 12),
      Text(
        'Proyectos asignados',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
    ];
    if (data.projects.isEmpty) {
      out.add(
        Text(
          'No tiene proyectos en esta área.',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
      );
      return out;
    }
    for (final p in data.projects) {
      final ratio = data.projectProgress[p.id] ?? 0.0;
      final pct = (ratio * 100).round();
      final col = PaletaPasteles.proyectoColorByMode(p.color, brightness);
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: col,
                    ),
                  ),
                ],
              ),
              if (p.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  p.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(col),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return out;
  }

  List<Widget> _saSeccionTrabajadores(
    BuildContext context,
    SaTeamAdminCardData data,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    return [
      const SizedBox(height: 4),
      Text(
        'Trabajadores del área (TA)',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      if (data.trabajadores.isEmpty)
        Text(
          'Ningún trabajador asignado a esta área.',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: data.trabajadores
              .map(
                (u) => Chip(
                  avatar: CircleAvatar(
                    maxRadius: 16,
                    child: Text(
                      u.firstName.isNotEmpty
                          ? u.firstName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  label: Text(u.fullName),
                  labelStyle: theme.textTheme.bodySmall,
                ),
              )
              .toList(),
        ),
    ];
  }

  Widget _buildPersonaCard(
    BuildContext context,
    UserModel persona,
    List<ActivityModel> actividades,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final contador = _contarPorEstado(actividades);
    final total = actividades.length;
    final completadas = contador[ActivityStatus.completada] ?? 0;
    final enProgreso = (contador[ActivityStatus.hoy] ?? 0) +
        (contador[ActivityStatus.manana] ?? 0) +
        (contador[ActivityStatus.programado] ?? 0);
    final muted = scheme.onSurfaceVariant;
    final initial = persona.firstName.isNotEmpty
        ? persona.firstName[0].toUpperCase()
        : '?';

    return Card(
      child: InkWell(
        onTap: () => _mostrarDetallePersona(context, persona, actividades),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        scheme.primary.withValues(alpha: 0.18),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          persona.fullName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          persona.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniMetrica(
                    context,
                    'Total',
                    total,
                    Icons.list,
                  ),
                  _buildMiniMetrica(
                    context,
                    'Completadas',
                    completadas,
                    Icons.star_outline,
                    ActivityStatusColors.forStatus(
                      ActivityStatus.completada,
                      brightness: theme.brightness,
                    ),
                  ),
                  _buildMiniMetrica(
                    context,
                    'En progreso',
                    enProgreso,
                    Icons.play_circle_outline,
                    PaletaPasteles.slidableMoverFondo(theme.brightness),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (total > 0) ...[
                Divider(color: scheme.outlineVariant),
                const SizedBox(height: 8),
                Text(
                  'Actividades asignadas: $total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completadas: $completadas | En proceso: $enProgreso',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetrica(
    BuildContext context,
    String label,
    int valor,
    IconData icono, [
    Color? color,
  ]) {
    final theme = Theme.of(context);
    final metricColor = color ?? theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Icon(icono, size: 20, color: metricColor),
        const SizedBox(height: 4),
        Text(
          valor.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: metricColor,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _mostrarDetallePersona(
    BuildContext context,
    UserModel persona,
    List<ActivityModel> actividades,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final initial = persona.firstName.isNotEmpty
        ? persona.firstName[0].toUpperCase()
        : '?';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        scheme.primary.withValues(alpha: 0.18),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          persona.fullName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          persona.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Expanded(
              child: actividades.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: muted),
                          const SizedBox(height: 16),
                          Text(
                            'No hay actividades asignadas',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: actividades.length,
                      itemBuilder: (_, index) {
                        final actividad = actividades[index];
                        final estadoColor = ActivityStatusColors.forStatus(
                          actividad.status,
                          brightness: theme.brightness,
                        );
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(actividad.title),
                            subtitle: Text(actividad.status.label),
                            trailing: Chip(
                              label: Text(actividad.status.label),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor:
                                  estadoColor.withValues(alpha: 0.2),
                            ),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              context.go('/activity/${actividad.id}');
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
