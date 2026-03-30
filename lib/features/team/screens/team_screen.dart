import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/team_provider.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Equipo')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: e.toString()),
        data: (members) {
          if (members.isEmpty) return const EmptyState(icon: Icons.group_outlined, title: 'Sin miembros', subtitle: 'Invita a tu equipo');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceBorder, height: 1),
            itemBuilder: (_, i) {
              final m = members[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: AppColors.purple.withValues(alpha: 0.2),
                  child: Text(
                    '${m.firstName[0]}${m.lastName.isNotEmpty ? m.lastName[0] : ''}',
                    style: const TextStyle(color: AppColors.purpleLight, fontWeight: FontWeight.w600),
                  ),
                ),
                title: Text(m.fullName, style: AppTextStyles.heading3),
                subtitle: Text(m.role.label, style: AppTextStyles.bodySecondary),
                trailing: m.areaName != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.surfaceBorder, borderRadius: BorderRadius.circular(12)),
                        child: Text(m.areaName!, style: AppTextStyles.caption),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
