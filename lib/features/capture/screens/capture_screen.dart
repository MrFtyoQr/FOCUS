import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../providers/capture_provider.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../features/projects/providers/projects_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/projects_access.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/activity_status_colors.dart';

/// Fondo de cards en Capturar (solo modo claro).
const _kCapturaCardBackgroundLight = Color(0xFFF7F7F7);

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  ActivityStatus _status = ActivityStatus.bandeja;
  String? _projectId;
  DateTime? _targetDate;
  final List<String> _attachmentPaths = [];

  Color? _capturaCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _kCapturaCardBackgroundLight
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: _targetDate != null
          ? TimeOfDay(hour: _targetDate!.hour, minute: _targetDate!.minute)
          : TimeOfDay.now(),
    );

    if (hora != null && mounted) {
      setState(() {
        _targetDate = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          hora.hour,
          hora.minute,
        );
      });
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      final picker = ImagePicker();
      final imagen = await picker.pickImage(source: ImageSource.gallery);
      if (imagen != null && mounted) {
        setState(() => _attachmentPaths.add(imagen.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error al seleccionar imagen: $e'),
        );
      }
    }
  }

  Future<void> _seleccionarArchivo() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null && mounted) {
        setState(() => _attachmentPaths.add(result.files.single.path!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error al seleccionar archivo: $e'),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_status == ActivityStatus.programado && _targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.aviso(
          'Las actividades programadas requieren una fecha objetivo',
        ),
      );
      return;
    }

    final notifier = ref.read(captureProvider.notifier);
    final outcome = await notifier.capture(
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      status: _status.apiValue,
      projectId: _projectId,
      targetDate:
          _status == ActivityStatus.programado ? _targetDate : null,
      attachmentPaths: List<String>.from(_attachmentPaths),
    );

    if (!mounted) return;

    if (outcome != null) {
      final hadAttachments = _attachmentPaths.isNotEmpty;
      if (outcome.hasUploadFailures) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.aviso(
            'Actividad creada. No se subieron: ${outcome.failedFiles.join(', ')}',
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.exito(
            hadAttachments
                ? 'Actividad creada con adjuntos'
                : 'Actividad creada exitosamente',
          ),
        );
      }
      _titleController.clear();
      _descController.clear();
      setState(() {
        _status = ActivityStatus.bandeja;
        _projectId = null;
        _targetDate = null;
        _attachmentPaths.clear();
      });
      context.go('/');
    }
  }

  static IconData _iconForStatus(ActivityStatus s) {
    return switch (s) {
      ActivityStatus.bandeja => Icons.inbox_outlined,
      ActivityStatus.hoy => Icons.today_outlined,
      ActivityStatus.manana => Icons.event_outlined,
      ActivityStatus.programado => Icons.schedule_outlined,
      ActivityStatus.pendientes => Icons.pause_circle_outline,
      ActivityStatus.completada => Icons.check_circle_outline,
    };
  }

  List<Widget> _buildEstadoChips() {
    return ActivityStatus.values
        .where((s) => s != ActivityStatus.completada)
        .map((s) => _buildEstadoChip(s))
        .toList();
  }

  Widget _buildEstadoChip(ActivityStatus estado) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    final isSelected = _status == estado;
    final color = ActivityStatusColors.forStatus(estado, brightness: brightness);
    final selectedForeground = isLight
        ? const Color(0xFFF3F5FA)
        : Color.lerp(color, const Color(0xFF1F2430), 0.82)!;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(estado.label),
      labelStyle: TextStyle(
        color: isSelected ? selectedForeground : color,
        fontWeight: FontWeight.w600,
      ),
      avatar: Icon(
        _iconForStatus(estado),
        size: 18,
        color: isSelected ? selectedForeground : color,
      ),
      selectedColor: color,
      elevation: isLight ? 0 : null,
      pressElevation: isLight ? 0 : null,
      shadowColor: isLight ? Colors.transparent : null,
      selectedShadowColor: isLight ? Colors.transparent : null,
      surfaceTintColor: isLight ? Colors.transparent : null,
      onSelected: (_) {
        setState(() {
          _status = estado;
          if (_status != ActivityStatus.programado) {
            _targetDate = null;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureProvider);
    final isLoading = captureState is AsyncLoading;
    final projectsAsync = ref.watch(projectsProvider);
    final theme = Theme.of(context);
    final maxWidth = Responsive.getMaxContentWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capturar actividad'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? double.infinity,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    hintText: '¿Qué necesitas hacer?',
                    prefixIcon: Icon(Icons.title),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Detalles adicionales (opcional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Card(
                  color: _capturaCardColor(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Destino inicial',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _buildEstadoChips(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                projectsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (projects) {
                    final user = ref.watch(currentUserProvider);
                    if (user == null) return const SizedBox.shrink();
                    final opts = projectsForCapture(user, projects);
                    final validIds = opts.map((p) => p.id).toSet();
                    if (_projectId != null && !validIds.contains(_projectId)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _projectId = null);
                      });
                    }
                    return Column(
                      children: [
                        Card(
                          color: _capturaCardColor(context),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Proyecto (opcional)',
                                  style: theme.textTheme.titleSmall,
                                ),
                                if (opts.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    user.isTrabajador || user.isPersonalAccount
                                        ? 'No tienes proyectos personales. Crea uno en la pestaña Proyectos.'
                                        : 'No hay proyectos disponibles para asignar con tu rol.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String?>(
                                    value: _projectId,
                                    decoration: const InputDecoration(
                                      hintText: 'Seleccionar proyecto',
                                      prefixIcon: Icon(Icons.folder),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Sin proyecto'),
                                      ),
                                      ...opts.map(
                                        (p) => DropdownMenuItem<String?>(
                                          value: p.id,
                                          child: Text(
                                            p.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _projectId = v),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                if (_status == ActivityStatus.programado) ...[
                  Card(
                    color: _capturaCardColor(context),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha objetivo *',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(
                              _targetDate != null
                                  ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year} '
                                      '${_targetDate!.hour.toString().padLeft(2, '0')}:'
                                      '${_targetDate!.minute.toString().padLeft(2, '0')}'
                                  : 'Seleccionar fecha y hora',
                              style: _targetDate == null
                                  ? theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    )
                                  : theme.textTheme.bodyLarge,
                            ),
                            trailing: _targetDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() => _targetDate = null);
                                    },
                                  )
                                : null,
                            onTap: _seleccionarFecha,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  color: _capturaCardColor(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Archivos adjuntos',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed:
                                  isLoading ? null : _seleccionarImagen,
                              icon: const Icon(Icons.image),
                              label: const Text('Imagen'),
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  isLoading ? null : _seleccionarArchivo,
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Archivo'),
                            ),
                          ],
                        ),
                        if (_attachmentPaths.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _attachmentPaths.map((archivo) {
                              return Chip(
                                label: Text(p.basename(archivo)),
                                onDeleted: isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _attachmentPaths.remove(archivo);
                                        });
                                      },
                                deleteIcon: const Icon(Icons.close),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (captureState is AsyncError) ...[
                  Text(
                    captureState.error
                        .toString()
                        .replaceFirst('Exception: ', ''),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    isLoading ? 'Guardando...' : 'Guardar actividad',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
