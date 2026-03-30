import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/capture_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/enums/activity_status.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});
  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  ActivityStatus _status    = ActivityStatus.bandeja;
  int?           _projectId;
  DateTime?      _targetDate;

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(captureProvider.notifier);
    final activity = await notifier.capture(
      title: _titleCtrl.text.trim(), description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      status: _status.name, projectId: _projectId, targetDate: _targetDate,
    );
    if (mounted && activity != null) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final isLoading = captureState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nueva actividad')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextFormField(
                controller: _titleCtrl, autofocus: true,
                decoration: const InputDecoration(labelText: 'Título *', hintText: '¿Qué necesitas hacer?', prefixIcon: Icon(Icons.edit_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'El título es requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)', prefixIcon: Icon(Icons.notes), alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ActivityStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Estado', prefixIcon: Icon(Icons.flag_outlined)),
                items: ActivityStatus.values
                    .where((s) => s != ActivityStatus.completada)
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                onChanged: (s) => setState(() => _status = s!),
              ),
              const SizedBox(height: 16),
              projectsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (projects) => projects.isEmpty ? const SizedBox.shrink()
                    : DropdownButtonFormField<int?>(
                        initialValue: _projectId,
                        decoration: const InputDecoration(labelText: 'Proyecto (opcional)', prefixIcon: Icon(Icons.folder_outlined)),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Sin proyecto')),
                          ...projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                        ],
                        onChanged: (v) => setState(() => _projectId = v),
                      ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setState(() => _targetDate = picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Fecha objetivo (opcional)', prefixIcon: Icon(Icons.calendar_today_outlined)),
                  child: Text(
                    _targetDate == null ? 'Sin fecha' : '${_targetDate!.day.toString().padLeft(2,'0')}/${_targetDate!.month.toString().padLeft(2,'0')}/${_targetDate!.year}',
                    style: AppTextStyles.body,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (captureState.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(captureState.error.toString(), style: const TextStyle(color: AppColors.red, fontSize: 13), textAlign: TextAlign.center),
                ),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Guardar actividad'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
