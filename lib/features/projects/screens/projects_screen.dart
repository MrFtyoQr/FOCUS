import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo proyecto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
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
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await ref.read(projectRepositoryProvider).createProject(
                    name: titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty
                        ? null : descCtrl.text.trim(),
                  );
              ref.invalidate(projectsProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    titleCtrl.dispose();
    descCtrl.dispose();
  }
}
