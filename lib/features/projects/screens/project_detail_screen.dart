import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../auth/providers/auth_provider.dart';
import '../../capture/providers/capture_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../team/providers/team_provider.dart';
import '../providers/projects_provider.dart';
import '../../../core/utils/activity_status_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/paleta_pasteles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/activity_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/models/project.dart';

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

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ProjectDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  ActivityStatus? _filtroEstado;

  List<ActivityModel> _filtradas(List<ActivityModel> todas) {
    if (_filtroEstado == null) return todas;
    return todas.where((a) => a.status == _filtroEstado).toList();
  }

  Future<void> _recargar() async {
    ref.invalidate(projectDetailProvider(widget.id));
    ref.invalidate(projectActivitiesProvider(widget.id));
    await Future.wait([
      ref.read(projectDetailProvider(widget.id).future),
      ref.read(projectActivitiesProvider(widget.id).future),
    ]);
  }

  IconData _iconEstado(ActivityStatus estado) {
    return switch (estado) {
      ActivityStatus.bandeja => Icons.inbox_outlined,
      ActivityStatus.hoy => Icons.today_outlined,
      ActivityStatus.manana => Icons.event_outlined,
      ActivityStatus.programado => Icons.schedule_outlined,
      ActivityStatus.pendientes => Icons.pause_circle_outline,
      ActivityStatus.completada => Icons.star_outline,
    };
  }

  Color _colorEstadoChip(ActivityStatus estado) {
    return ActivityStatusColors.forStatus(
      estado,
      brightness: Theme.of(context).brightness,
    );
  }

  Widget _estadoFilterChipDialog({
    required StateSetter setDialogState,
    required ActivityStatus estado,
    required ActivityStatus estadoSel,
    required void Function(ActivityStatus) onSel,
  }) {
    final isSel = estadoSel == estado;
    final color = _colorEstadoChip(estado);
    final icon = _iconEstado(estado);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lum = color.computeLuminance();
    final selectedForeground = isDark
        ? const Color(0xFFF3F5FA)
        : (lum > 0.45 ? const Color(0xFF1F2430) : const Color(0xFFF3F5FA));

    return FilterChip(
      selected: isSel,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 18,
        color: isSel ? selectedForeground : color,
      ),
      label: Text(estado.label),
      labelStyle: TextStyle(
        color: isSel ? selectedForeground : color,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: color,
      onSelected: (selected) {
        if (selected) {
          setDialogState(() => onSel(estado));
        }
      },
    );
  }

  Future<void> _mostrarDialogoNuevaActividad(ProjectModel proyecto) async {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    ActivityStatus estadoSel = ActivityStatus.bandeja;
    DateTime? fechaObjetivo;
    final adjuntos = <String>[];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Nueva actividad'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    hintText: '¿Qué necesitas hacer?',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Detalles adicionales (opcional)',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Estado inicial',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _estadoFilterChipDialog(
                      setDialogState: setSt,
                      estado: ActivityStatus.bandeja,
                      estadoSel: estadoSel,
                      onSel: (e) {
                        estadoSel = e;
                        if (e != ActivityStatus.programado) {
                          fechaObjetivo = null;
                        }
                      },
                    ),
                    _estadoFilterChipDialog(
                      setDialogState: setSt,
                      estado: ActivityStatus.hoy,
                      estadoSel: estadoSel,
                      onSel: (e) {
                        estadoSel = e;
                        if (e != ActivityStatus.programado) {
                          fechaObjetivo = null;
                        }
                      },
                    ),
                    _estadoFilterChipDialog(
                      setDialogState: setSt,
                      estado: ActivityStatus.manana,
                      estadoSel: estadoSel,
                      onSel: (e) {
                        estadoSel = e;
                        if (e != ActivityStatus.programado) {
                          fechaObjetivo = null;
                        }
                      },
                    ),
                    _estadoFilterChipDialog(
                      setDialogState: setSt,
                      estado: ActivityStatus.programado,
                      estadoSel: estadoSel,
                      onSel: (e) => estadoSel = e,
                    ),
                    _estadoFilterChipDialog(
                      setDialogState: setSt,
                      estado: ActivityStatus.pendientes,
                      estadoSel: estadoSel,
                      onSel: (e) {
                        estadoSel = e;
                        if (e != ActivityStatus.programado) {
                          fechaObjetivo = null;
                        }
                      },
                    ),
                  ],
                ),
                if (estadoSel == ActivityStatus.programado) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Fecha objetivo *',
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      fechaObjetivo != null
                          ? '${fechaObjetivo!.day}/${fechaObjetivo!.month}/${fechaObjetivo!.year} '
                              '${fechaObjetivo!.hour.toString().padLeft(2, '0')}:'
                              '${fechaObjetivo!.minute.toString().padLeft(2, '0')}'
                          : 'Seleccionar fecha y hora',
                    ),
                    trailing: fechaObjetivo != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setSt(() => fechaObjetivo = null),
                          )
                        : null,
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: ctx,
                        initialDate: fechaObjetivo ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (fecha == null || !ctx.mounted) return;
                      final hora = await showTimePicker(
                        context: ctx,
                        initialTime: fechaObjetivo != null
                            ? TimeOfDay(
                                hour: fechaObjetivo!.hour,
                                minute: fechaObjetivo!.minute,
                              )
                            : TimeOfDay.now(),
                      );
                      if (hora != null) {
                        setSt(() {
                          fechaObjetivo = DateTime(
                            fecha.year,
                            fecha.month,
                            fecha.day,
                            hora.hour,
                            hora.minute,
                          );
                        });
                      }
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Archivos adjuntos',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final x = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (x != null) {
                          setSt(() => adjuntos.add(x.path));
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Imagen'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final r = await FilePicker.platform.pickFiles();
                        if (r != null && r.files.single.path != null) {
                          setSt(() => adjuntos.add(r.files.single.path!));
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Archivo'),
                    ),
                  ],
                ),
                if (adjuntos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: adjuntos
                        .map(
                          (a) => Chip(
                            label: Text(p.basename(a)),
                            onDeleted: () => setSt(() => adjuntos.remove(a)),
                          ),
                        )
                        .toList(),
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
                if (tituloCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    final titulo = tituloCtrl.text.trim();
    final desc = descCtrl.text.trim();
    // Evita liberar controladores mientras el árbol del diálogo
    // aún está terminando su ciclo de desmontaje.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tituloCtrl.dispose();
      descCtrl.dispose();
    });

    if (ok != true || titulo.isEmpty) return;

    if (estadoSel == ActivityStatus.programado && fechaObjetivo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.aviso(
            'Las actividades programadas requieren una fecha objetivo',
          ),
        );
      }
      return;
    }

    final hadAdjuntos = adjuntos.isNotEmpty;
    final outcome = await ref.read(captureProvider.notifier).capture(
          title: titulo,
          description: desc.isEmpty ? null : desc,
          status: estadoSel.apiValue,
          projectId: widget.id,
          targetDate:
              estadoSel == ActivityStatus.programado ? fechaObjetivo : null,
          attachmentPaths: List<String>.from(adjuntos),
        );

    if (!mounted) return;

    if (outcome != null) {
      ref.invalidate(projectActivitiesProvider(widget.id));
      ref.invalidate(projectDetailProvider(widget.id));
      ref.invalidate(projectsProvider);

      if (outcome.hasUploadFailures) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.aviso(
            'Actividad creada. No se subieron: ${outcome.failedFiles.join(', ')}',
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.exito(
            hadAdjuntos
                ? 'Actividad creada con adjuntos'
                : 'Actividad creada exitosamente',
          ),
        );
      }
    } else {
      final err = ref.read(captureProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(
          err != null ? 'Error: $err' : 'No se pudo crear la actividad',
        ),
      );
    }
  }

  Future<void> _recargarProgresoSuperAdmin() async {
    ref.invalidate(projectProgressProvider(widget.id));
    await ref.read(projectProgressProvider(widget.id).future);
  }

  Widget _cuerpoProyectoSuperAdmin(
    BuildContext context,
    ProjectModel proyecto,
    Map<String, dynamic> progress,
    List<ActivityModel> actividades,
    String? nombreAreaResuelto,
    bool actividadesSoloDesdeListadoGlobal,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final proyectoColor = PaletaPasteles.proyectoColorByMode(
      proyecto.color,
      Theme.of(context).brightness,
    );
    final tintHeader = proyectoColor.withValues(alpha: 0.1);
    final totalApi = (progress['total'] as num?)?.toInt() ?? 0;
    final completedApi = (progress['completed'] as num?)?.toInt() ?? 0;
    final total = totalApi > 0 ? totalApi : actividades.length;
    final completed = totalApi > 0
        ? completedApi
        : actividades.where((a) => a.status == ActivityStatus.completada).length;
    final avance = total > 0 ? completed / total : 0.0;
    final descBox = Theme.of(context).brightness == Brightness.light
        ? scheme.surfaceContainerLowest.withValues(alpha: 0.9)
        : scheme.surfaceContainerHigh.withValues(alpha: 0.5);

    return RefreshIndicator(
      onRefresh: _recargarProgresoSuperAdmin,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
        children: [
          Material(
            color: tintHeader,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Las actividades las gestiona el administrador de área asignado. '
                'Aquí solo ves el resumen del proyecto.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (proyecto.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: descBox,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                proyecto.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          if (proyecto.description.isNotEmpty) const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.domain_outlined, color: scheme.primary),
            title: const Text('Área'),
            subtitle: Text(
              nombreAreaResuelto?.isNotEmpty == true
                  ? nombreAreaResuelto!
                  : (proyecto.areaId != null && proyecto.areaId!.isNotEmpty
                      ? 'Área asignada (sin nombre en API)'
                      : 'Sin área vinculada'),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.manage_accounts_outlined, color: scheme.primary),
            title: const Text('Administrador de área'),
            subtitle: Text(
              proyecto.areaAdminName?.isNotEmpty == true
                  ? proyecto.areaAdminName!
                  : 'Sin asignar (el API no envió area_admin_name)',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.flag_outlined, color: scheme.primary),
            title: const Text('Estado del proyecto'),
            subtitle: Text(_estadoProyectoLegible(proyecto.status)),
          ),
          const SizedBox(height: 16),
          Text(
            'Avance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (actividadesSoloDesdeListadoGlobal && actividades.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: scheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Las actividades se muestran desde el listado global '
                          'porque GET /api/projects/{id}/activities/ devolvió vacío. '
                          'Conviene alinear ambos en backend.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (total == 0 && actividades.isEmpty)
            Text(
              'Aún no hay actividades registradas en este proyecto.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            )
          else ...[
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$completed / $total completadas · ${(avance * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: avance > 0 ? avance : null,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(proyectoColor),
              ),
            ),
          ],
          if (actividades.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Desglose por estado',
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
                  if (actividades.where((a) => a.status == e).isNotEmpty)
                    Chip(
                      label: Text(
                        '${e.label}: '
                        '${actividades.where((a) => a.status == e).length}',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Actividades',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...actividades.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ActivityCard(
                  activity: a,
                  projectColorHex: proyecto.color,
                  onTap: () => context.go('/activity/${a.id}'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cuerpoProyecto(
    BuildContext context,
    ProjectModel proyecto,
    List<ActivityModel> actividades,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isTablet = Responsive.isTablet(context);
    final wide = MediaQuery.of(context).size.width > 700;
    final proyectoColor = PaletaPasteles.proyectoColorByMode(
      proyecto.color,
      Theme.of(context).brightness,
    );
    final tintHeader = proyectoColor.withValues(alpha: 0.1);
    final descBox = Theme.of(context).brightness == Brightness.light
        ? scheme.surfaceContainerLowest.withValues(alpha: 0.9)
        : scheme.surfaceContainerHigh.withValues(alpha: 0.5);

    final filtradas = _filtradas(actividades);
    final completadas = actividades
        .where((a) => a.status == ActivityStatus.completada)
        .length;

    final estadosFiltro = ActivityStatus.values
        .where((e) => e != ActivityStatus.completada)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
          color: tintHeader,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    avatar: const Icon(Icons.list, size: 18),
                    label: Text('${actividades.length} actividades'),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    avatar: const Icon(Icons.star_outline, size: 18),
                    label: Text('$completadas completadas'),
                  ),
                ],
              ),
              if (proyecto.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: descBox,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    proyecto.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
        LinearProgressIndicator(
          value: proyecto.progress,
          backgroundColor: scheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(proyectoColor),
          minHeight: 4,
        ),
        Padding(
          padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
          child: isTablet && wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SegmentedButton<ActivityStatus?>(
                        segments: [
                          const ButtonSegment<ActivityStatus?>(
                            value: null,
                            label: Text('Todas'),
                          ),
                          ...estadosFiltro.map(
                            (e) => ButtonSegment<ActivityStatus?>(
                              value: e,
                              label: Text(e.label),
                            ),
                          ),
                        ],
                        selected: {_filtroEstado},
                        onSelectionChanged: (s) {
                          setState(() => _filtroEstado = s.first);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () =>
                          _mostrarDialogoNuevaActividad(proyecto),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: estadosFiltro.length + 1,
                        itemBuilder: (_, index) {
                          final ActivityStatus? estado;
                          if (index == 0) {
                            estado = null;
                          } else {
                            estado = estadosFiltro[index - 1];
                          }
                          final isSel = estado == _filtroEstado;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSel,
                              label: Text(estado == null ? 'Todas' : estado.label),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _filtroEstado = estado);
                                }
                              },
                              selectedColor: scheme.primaryContainer,
                              checkmarkColor: scheme.onPrimaryContainer,
                              labelStyle: TextStyle(
                                color: isSel
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
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () =>
                          _mostrarDialogoNuevaActividad(proyecto),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva'),
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
                      Icon(Icons.inbox, size: 64, color: scheme.outline),
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
                            return ActivityCard(
                              activity: a,
                              projectColorHex: proyecto.color,
                              onTap: () =>
                                  context.go('/activity/${a.id}'),
                              onComplete: () async {
                                await ref
                                    .read(activityRepositoryProvider)
                                    .completeActivity(a.id);
                                ref.invalidate(
                                    projectActivitiesProvider(widget.id));
                                ref.invalidate(
                                    projectDetailProvider(widget.id));
                                ref.invalidate(projectsProvider);
                                ref.invalidate(dashboardProvider);
                                if (mounted) setState(() {});
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
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ActivityCard(
                                activity: a,
                                projectColorHex: proyecto.color,
                                onTap: () =>
                                    context.go('/activity/${a.id}'),
                                onComplete: () async {
                                  await ref
                                      .read(activityRepositoryProvider)
                                      .completeActivity(a.id);
                                  ref.invalidate(
                                      projectActivitiesProvider(
                                          widget.id));
                                  ref.invalidate(
                                      projectDetailProvider(widget.id));
                                  ref.invalidate(projectsProvider);
                                  ref.invalidate(dashboardProvider);
                                  if (mounted) setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailProvider(widget.id));
    final activitiesAsync =
        ref.watch(projectActivitiesProvider(widget.id));

    return projectAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Proyecto')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Proyecto')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No se pudo cargar el proyecto'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/projects'),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
      data: (proyecto) {
        final proyectoColor = PaletaPasteles.proyectoColorByMode(
          proyecto.color,
          Theme.of(context).brightness,
        );
        final tintAppBar = proyectoColor.withValues(alpha: 0.1);
        final isSa = ref.watch(
          currentUserProvider.select((u) => u?.isSuperAdmin ?? false),
        );

        final nestedActs =
            ref.watch(projectActivitiesProvider(widget.id)).valueOrNull ?? [];
        final globalActs =
            ref.watch(allActivitiesProvider).valueOrNull ?? [];
        final actividadesProyecto = nestedActs.isNotEmpty
            ? nestedActs
            : globalActs
                .where((a) => a.projectId == proyecto.id)
                .toList();
        final soloGlobal = nestedActs.isEmpty && actividadesProyecto.isNotEmpty;

        final areasRaw = ref.watch(areasCatalogProvider).valueOrNull ?? [];
        final areaIdToName = <String, String>{
          for (final a in areasRaw)
            if (a['id'] is String && a['name'] is String)
              a['id'] as String: a['name'] as String,
        };
        final nombreArea = proyecto.areaName?.trim().isNotEmpty == true
            ? proyecto.areaName!.trim()
            : (proyecto.areaId != null
                ? areaIdToName[proyecto.areaId!]
                : null);

        return Scaffold(
          appBar: AppBar(
            title: Text(proyecto.name),
            elevation: 0,
            backgroundColor: tintAppBar,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/projects'),
            ),
          ),
          body: isSa
              ? ref.watch(projectProgressProvider(widget.id)).when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Error al cargar el progreso',
                      subtitle: 'Intenta de nuevo más tarde',
                    ),
                    data: (prog) => _cuerpoProyectoSuperAdmin(
                          context,
                          proyecto,
                          prog,
                          actividadesProyecto,
                          nombreArea,
                          soloGlobal,
                        ),
                  )
              : activitiesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Error al cargar actividades',
                      subtitle: 'Intenta de nuevo más tarde',
                    ),
                    data: (acts) =>
                        _cuerpoProyecto(context, proyecto, acts),
                  ),
        );
      },
    );
  }
}
