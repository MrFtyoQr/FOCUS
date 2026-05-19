import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stats_repository.dart';

final statsRepositoryProvider = Provider((_) => StatsRepository());

/// Stats personales del usuario actual (trabajador)
final myStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(statsRepositoryProvider).getMyStats();
});

/// Stats del área — recibe el areaId del admin (adminArea)
final areaStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, areaId) {
  return ref.read(statsRepositoryProvider).getAreaStats(areaId);
});

/// Stats por trabajador del área (adminArea)
final workerStatsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(statsRepositoryProvider).getWorkerStats();
});

/// Stats de todas las áreas (superAdmin)
final allAreasStatsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(statsRepositoryProvider).getAllAreasStats();
});

final drilldownStatsProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, String?>>((ref, filters) {
  return ref.read(statsRepositoryProvider).getDrilldown(
    areaId:    filters['area'],
    projectId: filters['project'],
    userId:    filters['user'],
    from:      filters['from'],
    to:        filters['to'],
  );
});
