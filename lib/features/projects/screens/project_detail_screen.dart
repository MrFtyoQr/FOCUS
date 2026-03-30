import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/projects_provider.dart';
import '../../../core/widgets/activity_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final int id;
  const ProjectDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync    = ref.watch(projectDetailProvider(id));
    final activitiesAsync = ref.watch(projectActivitiesProvider(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Proyecto'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/projects')),
      ),
      body: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: e.toString()),
        data: (project) {
          final color = Color(int.parse(project.color.replaceFirst('#', 'FF'), radix: 16));
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 16, height: 16, margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    Expanded(child: Text(project.name, style: AppTextStyles.heading2)),
                    Text('${(project.progress * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                  ]),
                  if (project.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(project.description, style: AppTextStyles.bodySecondary),
                  ],
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: project.progress, minHeight: 6,
                      backgroundColor: color.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color)),
                  ),
                  const SizedBox(height: 8),
                  Text('${project.completedActivities} de ${project.totalActivities} completadas', style: AppTextStyles.caption),
                ]),
              )),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: Text('Actividades', style: AppTextStyles.heading2)),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              activitiesAsync.when(
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(child: EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: e.toString())),
                data: (activities) {
                  if (activities.isEmpty) return const SliverToBoxAdapter(child: EmptyState(icon: Icons.inbox, title: 'Sin actividades', subtitle: 'No hay actividades en este proyecto'));
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(delegate: SliverChildBuilderDelegate(
                      (_, i) => ActivityCard(activity: activities[i], onTap: () => context.go('/activity/${activities[i].id}')),
                      childCount: activities.length,
                    )),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}
