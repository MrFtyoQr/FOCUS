import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/projects_provider.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Proyectos'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreate(context, ref)),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: e.toString()),
        data: (projects) {
          if (projects.isEmpty) return const EmptyState(icon: Icons.folder_outlined, title: 'Sin proyectos', subtitle: 'Crea tu primer proyecto');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (_, i) {
              final p     = projects[i];
              final color = Color(int.parse(p.color.replaceFirst('#', 'FF'), radix: 16));
              return GestureDetector(
                onTap: () => context.go('/projects/${p.id}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 12, height: 12, margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      Expanded(child: Text(p.name, style: AppTextStyles.heading3)),
                      Text('${(p.progress * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                    if (p.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(p.description, style: AppTextStyles.bodySecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p.progress, minHeight: 4,
                        backgroundColor: color.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${p.completedActivities} de ${p.totalActivities} completadas', style: AppTextStyles.caption),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreate(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Nuevo proyecto', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nombre del proyecto')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () { Navigator.pop(context); ref.invalidate(projectsProvider); }, child: const Text('Crear proyecto')),
        ]),
      ),
    );
  }
}
