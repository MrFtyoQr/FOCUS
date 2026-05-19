import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _labelRol(String role) => switch (role) {
        'super_admin' => 'Super Admin',
        'admin_area'  => 'Admin de Área',
        _             => 'Trabajador',
      };

  /// Muestra el código de invitación generado con botón de copiar.
  Future<void> _mostrarDialogoEnlace(
    String token,
    String role, {
    String? expiresAt,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme  = Theme.of(ctx);
        final scheme = theme.colorScheme;
        return AlertDialog(
          title: Text('Código para ${_labelRol(role)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comparte este código con el nuevo integrante. '
                'Debe abrirlo en la app y pegarlo en "Tengo un código de invitación".',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              // ── Código destacado ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código de invitación',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      token,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (expiresAt != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expira: $expiresAt',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(context).showSnackBar(
                  AppSnackBar.exito('Código copiado al portapapeles'),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar código'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Listo'),
            ),
          ],
        );
      },
    );
  }

  // ── Invitar SA: elige rol y área (con creación inline) ───────────────────

  Future<void> _invitarSA() async {
    final repo = ref.read(teamRepositoryProvider);

    List<Map<String, dynamic>> areasList = [];
    try {
      areasList = await repo.getAreas();
    } catch (_) {}
    if (!mounted) return;

    var rolSeleccionado = 'admin_area';
    var areaIdSeleccionado =
        areasList.isNotEmpty ? areasList.first['id'] as String : '';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Crear área inline desde el mismo diálogo
          Future<void> crearAreaInline() async {
            final nameCtrl = TextEditingController();
            final descCtrl = TextEditingController();
            // Usamos el context del widget padre (no ctx de StatefulBuilder)
            // para evitar usar un BuildContext potencialmente obsoleto.
            if (!context.mounted) return;
            final ok = await showDialog<bool>(
              context: context,
              builder: (innerCtx) => AlertDialog(
                title: const Text('Nueva área'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(innerCtx, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isNotEmpty) {
                        Navigator.pop(innerCtx, true);
                      }
                    },
                    child: const Text('Crear'),
                  ),
                ],
              ),
            );
            final name = nameCtrl.text.trim();
            final desc = descCtrl.text.trim();
            // Diferir dispose al siguiente frame para evitar la condición de
            // carrera con la limpieza de elementos de la UI del diálogo
            // (causante del assertion '_dependents.isEmpty' en framework.dart).
            WidgetsBinding.instance.addPostFrameCallback((_) {
              nameCtrl.dispose();
              descCtrl.dispose();
            });
            if (ok != true || name.isEmpty) return;

            try {
              final nueva = await repo.createArea(
                name: name,
                description: desc.isEmpty ? null : desc,
              );
              setDialogState(() {
                areasList = [...areasList, nueva];
                areaIdSeleccionado = nueva['id'] as String;
              });
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  AppSnackBar.error('No se pudo crear el área: $e'),
                );
              }
            }
          }

          return AlertDialog(
            title: const Text('Invitar al equipo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rol a invitar',
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  RadioListTile<String>(
                    dense: true,
                    title: const Text('Super Admin'),
                    subtitle: const Text('Acceso completo a la organización'),
                    value: 'super_admin',
                    groupValue: rolSeleccionado,
                    onChanged: (v) =>
                        setDialogState(() => rolSeleccionado = v!),
                  ),
                  RadioListTile<String>(
                    dense: true,
                    title: const Text('Admin de Área'),
                    subtitle: const Text('Gestiona un área y su equipo'),
                    value: 'admin_area',
                    groupValue: rolSeleccionado,
                    onChanged: (v) =>
                        setDialogState(() => rolSeleccionado = v!),
                  ),
                  RadioListTile<String>(
                    dense: true,
                    title: const Text('Trabajador'),
                    subtitle: const Text('Miembro de un área'),
                    value: 'trabajador',
                    groupValue: rolSeleccionado,
                    onChanged: (v) =>
                        setDialogState(() => rolSeleccionado = v!),
                  ),
                  if (rolSeleccionado != 'super_admin') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: areasList.isEmpty
                              ? Text(
                                  'Sin áreas — crea una primero.',
                                  style: TextStyle(
                                    color: Theme.of(ctx).colorScheme.error,
                                    fontSize: 13,
                                  ),
                                )
                              : InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Área *',
                                    prefixIcon: Icon(Icons.groups_outlined),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.auto,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: areaIdSeleccionado.isEmpty
                                          ? areasList.first['id'] as String
                                          : areaIdSeleccionado,
                                      isExpanded: true,
                                      items: areasList.map((a) {
                                        return DropdownMenuItem<String>(
                                          value: a['id'] as String,
                                          child: Text(
                                            a['name'] as String? ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (v) {
                                        if (v == null) return;
                                        setDialogState(
                                          () => areaIdSeleccionado = v,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Nueva área',
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: crearAreaInline,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed:
                    rolSeleccionado != 'super_admin' && areasList.isEmpty
                        ? null
                        : () => Navigator.pop(ctx, true),
                child: const Text('Generar enlace'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      final areaArg =
          rolSeleccionado == 'super_admin' ? null : areaIdSeleccionado;
      final map = await repo.generateInvite(
        areaId: areaArg,
        role: rolSeleccionado,
      );
      if (!mounted) return;
      // El backend devuelve 'code' (código corto) o 'token' como fallback.
      final code = map['code'] as String?
          ?? map['token'] as String?
          ?? '';
      await _mostrarDialogoEnlace(
        code,
        rolSeleccionado,
        expiresAt: map['expires_at'] as String?,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('No se pudo generar la invitación: $e'),
        );
      }
    }
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
      if (!mounted) return;
      final code = map['code'] as String?
          ?? map['token'] as String?
          ?? '';
      await _mostrarDialogoEnlace(
        code,
        'trabajador',
        expiresAt: map['expires_at'] as String?,
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
                  onPressed: null,
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
              tooltip: 'Invitar al equipo',
              onPressed: _invitarSA,
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
                      onPressed: _invitarSA,
                      icon: const Icon(Icons.add),
                      label: const Text('Invitar al equipo'),
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

    // Los trabajadores no tienen permiso para listar usuarios (/api/users/ → 403).
    // Mostramos una vista informativa en lugar de lanzar la llamada.
    if (user.isTrabajador) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equipo'), elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, size: 72, color: muted),
                const SizedBox(height: 20),
                Text(
                  'Vista de equipo',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Solo los administradores pueden gestionar el equipo.\n'
                  'Contacta a tu administrador de área para cualquier cambio.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: muted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
              tooltip: 'Invitar trabajador',
              onPressed: _invitarTrabajadorArea,
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
                      onPressed: _invitarTrabajadorArea,
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
                (u) => ActionChip(
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
                  onPressed: () => _mostrarInfoTrabajador(context, u),
                ),
              )
              .toList(),
        ),
    ];
  }

  void _mostrarInfoTrabajador(BuildContext context, UserModel u) {
    final theme  = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted  = scheme.onSurfaceVariant;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                u.firstName.isNotEmpty ? u.firstName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                u.fullName,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(context, Icons.email_outlined, 'Correo', u.email),
            const SizedBox(height: 8),
            _infoRow(context, Icons.badge_outlined, 'Rol', 'Trabajador'),
            if (u.areaName != null) ...[
              const SizedBox(height: 8),
              _infoRow(context, Icons.group_work_outlined, 'Área', u.areaName!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final theme  = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
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
