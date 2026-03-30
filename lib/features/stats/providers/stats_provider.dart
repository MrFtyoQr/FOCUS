import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stats_repository.dart';

final statsRepositoryProvider = Provider((_) => StatsRepository());

final myStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(statsRepositoryProvider).getMyStats();
});

final areaStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(statsRepositoryProvider).getAreaStats();
});
