import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/projects_provider.dart';
import '../../../core/widgets/activity_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/theme/app_colors.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String id;
  const ProjectDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync    = ref.watch(projectDetailProvider(id));
    final activitiesAsync = ref.watch(projectActivitiesProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: projectAsync.when(
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Proyecto'),
          data: (p) => Text(p.name),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/projects'),
        ),
      ),
      body: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
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
        data: (project) {
          final color = _hexToColor(project.color);
          return Column(
            children: [
              // Header del proyecto
              Container(
                padding: const EdgeInsets.all(20),
                color: color.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.2),
                      radius: 28,
                      child: Icon(Icons.folder, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(project.name,
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          if (project.description.isNotEmpty)
                            Text(project.description,
                                style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${(project.progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          '${project.completedActivities}/${project.totalActivities}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Barra de progreso
              LinearProgressIndicator(
                value: project.progress,
                backgroundColor:
                    AppColors.surfaceBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
              // Actividades del proyecto
              Expanded(
                child: activitiesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Error al cargar actividades',
                    subtitle: 'Intenta de nuevo más tarde',
                  ),
                  data: (activities) => activities.isEmpty
                      ? const EmptyState(
                          icon: Icons.task_outlined,
                          title: 'Sin actividades',
                          subtitle:
                              'Captura la primera actividad de este proyecto.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: activities.length,
                          itemBuilder: (_, i) => ActivityCard(
                            activity: activities[i],
                            onTap: () =>
                                context.go('/activity/${activities[i].id}'),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.purple;
    }
  }
}
