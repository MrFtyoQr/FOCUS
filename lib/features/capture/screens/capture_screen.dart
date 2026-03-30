import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/capture_provider.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../features/projects/providers/projects_provider.dart';
import '../../../core/utils/responsive.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController  = TextEditingController();
  ActivityStatus _status = ActivityStatus.bandeja;
  int? _projectId;
  DateTime? _targetDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(captureProvider.notifier);
    final activity = await notifier.capture(
      title:       _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null : _descController.text.trim(),
      status:      _status.name,
      projectId:   _projectId,
      targetDate:  _targetDate,
    );

    if (!mounted) return;

    if (activity != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actividad creada')),
      );
      _titleController.clear();
      _descController.clear();
      setState(() {
        _status    = ActivityStatus.bandeja;
        _projectId = null;
        _targetDate = null;
      });
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureProvider);
    final isLoading    = captureState is AsyncLoading;
    final isDesktop    = Responsive.isDesktop(context);
    final projectsAsync = ref.watch(projectsProvider);
    final theme        = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva actividad')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.getHorizontalPadding(context),
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: isDesktop ? 600 : double.infinity),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        hintText: '¿Qué hay que hacer?',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'El título es obligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Estado inicial
                    DropdownButtonFormField<ActivityStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Estado inicial',
                        prefixIcon: Icon(Icons.flag_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: ActivityStatus.values
                          .where((s) => s != ActivityStatus.completada)
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ))
                          .toList(),
                      onChanged: (s) => setState(() => _status = s!),
                    ),
                    const SizedBox(height: 16),
                    // Proyecto (opcional)
                    projectsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (projects) => projects.isEmpty
                          ? const SizedBox.shrink()
                          : DropdownButtonFormField<int?>(
                              initialValue: _projectId,
                              decoration: const InputDecoration(
                                labelText: 'Proyecto (opcional)',
                                prefixIcon: Icon(Icons.folder_outlined),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12))),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('Sin proyecto')),
                                ...projects.map((p) => DropdownMenuItem<int?>(
                                      value: p.id,
                                      child: Text(p.name),
                                    )),
                              ],
                              onChanged: (v) =>
                                  setState(() => _projectId = v),
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Fecha objetivo
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _targetDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 2)),
                        );
                        if (picked != null) {
                          setState(() => _targetDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha objetivo (opcional)',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12))),
                        ),
                        child: Text(
                          _targetDate == null
                              ? 'Sin fecha'
                              : '${_targetDate!.day.toString().padLeft(2, '0')}/'
                                '${_targetDate!.month.toString().padLeft(2, '0')}/'
                                '${_targetDate!.year}',
                          style: _targetDate == null
                              ? theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant)
                              : theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    if (captureState is AsyncError) ...[
                      const SizedBox(height: 12),
                      Text(
                        captureState.error.toString().replaceFirst('Exception: ', ''),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary),
                              ),
                            )
                          : const Icon(Icons.add_circle_outline),
                      label: Text(
                        isLoading ? 'Guardando...' : 'Capturar actividad',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
