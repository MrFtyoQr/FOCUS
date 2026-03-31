import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stats_repository.dart';

final statsRepositoryProvider = Provider((_) => StatsRepository());

final myStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(statsRepositoryProvider).getMyStats();
});

final areaStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(statsRepositoryProvider).getAreaStats();
});

/// Stats de cada trabajador del área (para AdminArea)
final workerStatsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(statsRepositoryProvider).getWorkerStats();
});

/// Stats de todas las áreas (para SuperAdmin)
final allAreasStatsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(statsRepositoryProvider).getAllAreasStats();
});
