import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/project_repository.dart';
import '../../../shared/models/project.dart';
import '../../../shared/models/activity.dart';

final projectRepositoryProvider = Provider((_) => ProjectRepository());

final projectsProvider = FutureProvider<List<ProjectModel>>((ref) {
  return ref.read(projectRepositoryProvider).getProjects();
});

final projectDetailProvider =
    FutureProvider.family<ProjectModel, int>((ref, id) {
  return ref.read(projectRepositoryProvider).getProject(id);
});

final projectActivitiesProvider =
    FutureProvider.family<List<ActivityModel>, int>((ref, projectId) {
  return ref.read(projectRepositoryProvider).getProjectActivities(projectId);
});
