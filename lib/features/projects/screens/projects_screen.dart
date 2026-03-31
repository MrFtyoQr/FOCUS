import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/project_repository.dart';
import '../providers/projects_provider.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/responsive.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final isDesktop     = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(projectsProvider),
          ),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No se pudieron cargar los proyectos'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(projectsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (projects) => projects.isEmpty
            ? const EmptyState(
                icon: Icons.folder_open_outlined,
                title: 'Sin proyectos',
                subtitle: 'Crea tu primer proyecto para organizar actividades.',
              )
            : ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: 12,
                ),
                itemCount: projects.length,
                itemBuilder: (_, i) {
                  final p = projects[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _hexToColor(p.color).withValues(alpha: 0.2),
                        child: Icon(Icons.folder,
                            color: _hexToColor(p.color), size: 22),
                      ),
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.completedActivities}/${p.totalActivities} actividades',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(p.progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _hexToColor(p.color),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => context.go('/projects/${p.id}'),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF7F77DD);
    }
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CreateProjectDialog(
        onCreated: () {
          ref.invalidate(projectsProvider);
        },
        repositoryReader: () => ref.read(projectRepositoryProvider),
      ),
    );
  }
}

// Diálogo como StatefulWidget para gestión correcta del ciclo de vida
class _CreateProjectDialog extends StatefulWidget {
  final VoidCallback onCreated;
  final ProjectRepository Function() repositoryReader;

  const _CreateProjectDialog({
    required this.onCreated,
    required this.repositoryReader,
  });

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool  _loading   = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.repositoryReader().createProject(
        name:        _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      widget.onCreated();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo proyecto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre *',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}
