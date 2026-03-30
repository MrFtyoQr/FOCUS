import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/team_repository.dart';
import '../../../shared/models/user.dart';

final teamRepositoryProvider = Provider((_) => TeamRepository());

final teamMembersProvider = FutureProvider<List<UserModel>>((ref) =>
    ref.read(teamRepositoryProvider).getTeamMembers());

final areaMembersProvider = FutureProvider.family<List<UserModel>, int>((ref, areaId) =>
    ref.read(teamRepositoryProvider).getAreaMembers(areaId));
