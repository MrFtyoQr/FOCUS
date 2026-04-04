import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../projects/providers/projects_provider.dart';
import '../../team/providers/team_provider.dart';
import '../providers/activity_detail_bundle_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../shared/models/user.dart';
import '../../../core/utils/activity_status_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/mover_actividad_bottom_sheet.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ActivityDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ActivityDetailScreen> createState() =>
      _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  void _invalidate() {
    ref.invalidate(activityDetailBundleProvider(widget.id));
    ref.invalidate(dashboardProvider);
  }

  // ── Helpers visuales ─────────────────────────────────────────────────────

  Color _estadoColor(ActivityStatus estado) => ActivityStatusColors.forStatus(
        estado,
        brightness: Theme.of(context).brightness,
      );

  IconData _estadoIcon(ActivityStatus estado) => switch (estado) {
        ActivityStatus.bandeja    => Icons.inbox_outlined,
        ActivityStatus.hoy        => Icons.today_outlined,
        ActivityStatus.manana     => Icons.event_outlined,
        ActivityStatus.programado => Icons.schedule_outlined,
        ActivityStatus.pendientes => Icons.pause_circle_outline,
        ActivityStatus.completada => Icons.star_outline,
      };

  IconData _logIcon(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('creat')) return Icons.add_circle_outline;
    if (t.contains('mov'))   return Icons.swap_horiz;
    if (t.contains('compl')) return Icons.star_outline;
    if (t.contains('assign')) return Icons.person_outline;
    if (t.contains('attach')) return Icons.attach_file_outlined;
    if (t.contains('delet')) return Icons.delete_outline;
    return Icons.edit_outlined;
  }

  String? _attachmentUrl(Map<String, dynamic> m) {
    for (final k in ['url', 'file', 'download_url', 'file_url']) {
      final v = m[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  String _attachmentName(Map<String, dynamic> m) =>
      (m['name'] ?? m['filename'] ?? m['original_name'] ?? 'Archivo')
          .toString();

  String? _attachmentId(Map<String, dynamic> m) => m['id']?.toString();

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.aviso('No se pudo abrir el archivo'),
        );
      }
    }
  }

  Future<void> _mover(ActivityDetailBundle bundle) async {
    mostrarMoverActividadBottomSheet(
      context,
      bundle.activity,
      (nuevo) async {
        try {
          await ref
              .read(activityRepositoryProvider)
              .moveActivity(bundle.activity.id, nuevo.apiValue);
          _invalidate();
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(AppSnackBar.exito('Estado actualizado'));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(AppSnackBar.error('$e'));
          }
        }
      },
    );
  }

  Future<void> _completar(ActivityDetailBundle bundle) async {
    try {
      await ref
          .read(activityRepositoryProvider)
          .completeActivity(bundle.activity.id);
      _invalidate();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error('$e'));
      }
    }
  }

  Future<void> _mostrarAsignar(ActivityDetailBundle bundle) async {
    final repo  = ref.read(activityRepositoryProvider);
    final users = await ref.read(teamMembersProvider.future);
    if (!mounted) return;
    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.aviso('No hay personas en el equipo'),
      );
      return;
    }
    final selected = await showDialog<UserModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Asignar persona'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              final initial =
                  u.firstName.isNotEmpty ? u.firstName[0].toUpperCase() : '?';
              return ListTile(
                leading: CircleAvatar(child: Text(initial)),
                title: Text(u.fullName),
                subtitle: Text(u.email),
                onTap: () => Navigator.pop(ctx, u),
              );
            },
          ),
        ),
      ),
    );
    if (selected == null) return;
    try {
      await repo.assignActivity(bundle.activity.id, selected.id);
      _invalidate();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(AppSnackBar.exito('Asignación actualizada'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error('$e'));
      }
    }
  }

  Future<void> _quitarAsignacion(ActivityDetailBundle bundle) async {
    try {
      await ref
          .read(activityRepositoryProvider)
          .unassignActivity(bundle.activity.id);
      _invalidate();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(AppSnackBar.exito('Asignación eliminada'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error('$e'));
      }
    }
  }

  Future<void> _notaRapida(ActivityDetailBundle bundle) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar nota'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Escribe una nota…'),
          maxLines: 5,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) {
      ctrl.dispose();
      return;
    }
    final repo = ref.read(activityRepositoryProvider);
    final a    = bundle.activity;
    final bloque =
        '\n\n[Nota ${DateTime.now().toIso8601String().substring(0, 16)}] '
        '${ctrl.text.trim()}';
    ctrl.dispose();
    try {
      await repo.updateActivity(a.id, {
        'description': a.description.isEmpty
            ? bloque.trim()
            : '${a.description}$bloque',
      });
      _invalidate();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(AppSnackBar.exito('Nota agregada'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error('$e'));
      }
    }
  }

  Future<void> _agregarArchivoDialog(ActivityDetailBundle bundle) async {
    final op = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar archivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Seleccionar imagen'),
              onTap: () => Navigator.pop(ctx, 'imagen'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Seleccionar archivo'),
              onTap: () => Navigator.pop(ctx, 'archivo'),
            ),
          ],
        ),
      ),
    );
    if (op == 'imagen') {
      await _subirDesdeGaleria(bundle);
    } else if (op == 'archivo') {
      await _subirDesdeFilePicker(bundle);
    }
  }

  Future<void> _subirDesdeGaleria(ActivityDetailBundle bundle) async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x == null) return;
      await ref.read(activityRepositoryProvider).uploadAttachment(
            bundle.activity.id, x.path, p.basename(x.path));
      _invalidate();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(AppSnackBar.exito('Archivo subido'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error('$e'));
      }
    }
  }

  Future<void> _subirDesdeFilePicker(ActivityDetailBundle bundle) async {
    try {
      final r = await FilePicker.platform.pickFiles();
      if (r == null || r.files.single.path == null) return;
      final path = r.files.single.path!;
      await ref.read(activityRepositoryProvider).uploadAttachment(
            bundle.activity.id, path, p.basename(path));
      _invalidate();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(AppSnackBar.exito('Archivo subido'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error('$e'));
      }
    }
  }

  Future<void> _eliminarAdjunto(
    ActivityDetailBundle bundle,
    Map<String, dynamic> item,
  ) async {
    final attId = _attachmentId(item);
    if (attId == null || attId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.aviso('Este adjunto no se puede eliminar desde la app'),
      );
      return;
    }
    final name = _attachmentName(item);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content: Text('¿Eliminar "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(activityRepositoryProvider)
          .deleteAttachment(bundle.activity.id, attId);
      _invalidate();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(AppSnackBar.exito('Archivo eliminado'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error('$e'));
      }
    }
  }

  Future<void> _editarActividad(ActivityDetailBundle bundle) async {
    final projects = await ref.read(projectsProvider.future);
    if (!mounted) return;
    final a           = bundle.activity;
    final tituloCtrl  = TextEditingController(text: a.title);
    final descCtrl    = TextEditingController(text: a.description);
    ActivityStatus estadoSel = a.status;
    String? proyectoId       = a.projectId;
    DateTime? fechaObj       = a.targetDate;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Editar actividad'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(labelText: 'Título *'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Descripción'),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Text('Estado',
                    style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ActivityStatus.values
                      .where((s) => s != ActivityStatus.completada)
                      .map((estado) => FilterChip(
                            selected: estadoSel == estado,
                            label: Text(estado.label),
                            onSelected: (_) => setSt(() {
                              estadoSel = estado;
                              if (estadoSel != ActivityStatus.programado) {
                                fechaObj = null;
                              }
                            }),
                          ))
                      .toList(),
                ),
                if (projects.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: proyectoId,
                    decoration:
                        const InputDecoration(labelText: 'Proyecto'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Sin proyecto')),
                      ...projects.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          )),
                    ],
                    onChanged: (v) => setSt(() => proyectoId = v),
                  ),
                ],
                if (estadoSel == ActivityStatus.programado) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      fechaObj != null
                          ? '${fechaObj!.day}/${fechaObj!.month}/${fechaObj!.year} '
                              '${fechaObj!.hour.toString().padLeft(2, '0')}:'
                              '${fechaObj!.minute.toString().padLeft(2, '0')}'
                          : 'Seleccionar fecha y hora',
                    ),
                    trailing: fechaObj != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setSt(() => fechaObj = null),
                          )
                        : null,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: fechaObj ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (d == null || !ctx.mounted) return;
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: fechaObj != null
                            ? TimeOfDay(
                                hour: fechaObj!.hour,
                                minute: fechaObj!.minute)
                            : TimeOfDay.now(),
                      );
                      if (t != null) {
                        setSt(() => fechaObj = DateTime(
                              d.year, d.month, d.day, t.hour, t.minute));
                      }
                    },
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
              onPressed: () {
                if (tituloCtrl.text.trim().isEmpty) return;
                if (estadoSel == ActivityStatus.programado &&
                    fechaObj == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(AppSnackBar.aviso(
                    'Las actividades programadas requieren fecha objetivo',
                  ));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    final titulo     = tituloCtrl.text.trim();
    final descripcion = descCtrl.text.trim();
    tituloCtrl.dispose();
    descCtrl.dispose();

    if (ok != true) return;
    if (estadoSel == ActivityStatus.programado && fechaObj == null) return;

    try {
      await ref.read(activityRepositoryProvider).updateActivity(
        bundle.activity.id,
        {
          'title':       titulo,
          'description': descripcion,
          'status':      estadoSel.apiValue,
          'project':     proyectoId,
          if (fechaObj != null)
            'target_date': fechaObj!.toIso8601String().split('T').first,
        },
      );
      _invalidate();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(AppSnackBar.exito('Actividad actualizada'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error('$e'));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(activityDetailBundleProvider(widget.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de actividad'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          async.maybeWhen(
            data: (bundle) => PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editarActividad(bundle);
                  case 'move':
                    _mover(bundle);
                  case 'complete':
                    _completar(bundle);
                  case 'note':
                    _notaRapida(bundle);
                  case 'attach':
                    _agregarArchivoDialog(bundle);
                  case 'assign':
                    _mostrarAsignar(bundle);
                  case 'unassign':
                    _quitarAsignacion(bundle);
                }
              },
              itemBuilder: (ctx) => [
                if (!bundle.activity.isCompleted) ...[
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'move',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.swap_horiz),
                      title: Text('Cambiar estado'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'complete',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('Completar'),
                    ),
                  ),
                  const PopupMenuDivider(),
                ],
                const PopupMenuItem(
                  value: 'note',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.note_add_outlined),
                    title: Text('Agregar nota'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'attach',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.attach_file),
                    title: Text('Adjuntar archivo'),
                  ),
                ),
                if (bundle.activity.assignedToId == null)
                  const PopupMenuItem(
                    value: 'assign',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.person_add_outlined),
                      title: Text('Asignar persona'),
                    ),
                  )
                else
                  const PopupMenuItem(
                    value: 'unassign',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.person_remove_outlined),
                      title: Text('Quitar asignación'),
                    ),
                  ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
        data: (bundle) => _buildContent(bundle),
      ),
    );
  }

  Widget _buildContent(ActivityDetailBundle bundle) {
    final a       = bundle.activity;
    final theme   = Theme.of(context);
    final scheme  = theme.colorScheme;
    final muted   = scheme.onSurfaceVariant;
    final pad     = Responsive.getHorizontalPadding(context);
    final estadoColor = _estadoColor(a.status);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, 20, pad, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título ──────────────────────────────────────────────────────
          Text(
            a.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // ── Estado ──────────────────────────────────────────────────────
          Chip(
            avatar: Icon(_estadoIcon(a.status), size: 18, color: estadoColor),
            label: Text(a.status.label),
            backgroundColor: estadoColor.withValues(alpha: 0.12),
            side: BorderSide(color: estadoColor.withValues(alpha: 0.6)),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),

          // ── Descripción ─────────────────────────────────────────────────
          if (a.description.isNotEmpty) ...[
            Text('Descripción',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(a.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
          ],

          // ── Info ────────────────────────────────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Información',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  _infoFila(Icons.person_outline, 'Creada por', a.ownerName),
                  if (a.assignedToName != null)
                    _infoFila(Icons.person, 'Asignada a', a.assignedToName!),
                  if (a.projectName != null)
                    _infoFila(Icons.folder, 'Proyecto', a.projectName!),
                  if (a.areaName != null)
                    _infoFila(
                        Icons.business_outlined, 'Área', a.areaName!),
                  if (a.targetDate != null)
                    _infoFila(
                      Icons.calendar_today,
                      'Fecha objetivo',
                      '${a.targetDate!.day}/${a.targetDate!.month}/${a.targetDate!.year}',
                    ),
                  _infoFila(
                    Icons.access_time,
                    'Creada',
                    '${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year}',
                  ),
                  _infoFila(
                    Icons.update,
                    'Actualizada',
                    '${a.updatedAt.day}/${a.updatedAt.month}/${a.updatedAt.year}',
                  ),
                  if (a.completedAt != null)
                    _infoFila(
                      Icons.check_circle_outline,
                      'Completada',
                      '${a.completedAt!.day}/${a.completedAt!.month}/${a.completedAt!.year}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Adjuntos ────────────────────────────────────────────────────
          if (bundle.attachments.isNotEmpty) ...[
            Text(
              'Archivos adjuntos (${bundle.attachments.length})',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bundle.attachments.map((m) {
                final url  = _attachmentUrl(m);
                final name = _attachmentName(m);
                return InputChip(
                  label: Text(name, overflow: TextOverflow.ellipsis),
                  onPressed: url != null ? () => _abrirUrl(url) : null,
                  onDeleted: _attachmentId(m) != null
                      ? () => _eliminarAdjunto(bundle, m)
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // ── Bitácora ────────────────────────────────────────────────────
          Row(
            children: [
              Text('Bitácora',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Icon(Icons.history, size: 18, color: muted),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Historial de cambios de esta actividad',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),

          if (bundle.logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Sin eventos registrados',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
            )
          else
            ...bundle.logs.map((evento) {
              final tipo = (evento['event_type'] ??
                      evento['type'] ??
                      evento['action'] ??
                      'evento')
                  .toString();

              final rawDetail = evento['detail'] ??
                  evento['description'] ??
                  evento['message'];
              final String desc;
              if (rawDetail == null) {
                desc = '';
              } else if (rawDetail is Map) {
                desc = rawDetail.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join(' · ');
              } else {
                desc = rawDetail.toString();
              }

              DateTime? ts;
              final raw = evento['timestamp'] ?? evento['created_at'];
              if (raw is String) ts = DateTime.tryParse(raw);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: scheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_logIcon(tipo),
                              size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tipo,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (ts != null)
                            Text(
                              '${ts.day}/${ts.month}/${ts.year} '
                              '${ts.hour.toString().padLeft(2, '0')}:'
                              '${ts.minute.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: muted),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _infoFila(IconData icon, String etiqueta, String valor) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta,
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: muted)),
                Text(valor,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
