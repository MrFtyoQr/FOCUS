import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/team_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AssignScreen extends ConsumerStatefulWidget {
  final int activityId;
  const AssignScreen({super.key, required this.activityId});
  @override
  ConsumerState<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends ConsumerState<AssignScreen> {
  int? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teamMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Asignar actividad'), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.go('/team'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: e.toString()),
        data: (members) => Column(children: [
          Expanded(child: ListView.builder(
            itemCount: members.length,
            itemBuilder: (_, i) {
              final m = members[i];
              return ListTile(
                leading: Radio<int>(
                  value: m.id,
                  // ignore: deprecated_member_use
                  groupValue: _selectedUserId ?? -1,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setState(() => _selectedUserId = v),
                ),
                title: Text(m.fullName, style: AppTextStyles.body),
                subtitle: Text(m.role.label, style: AppTextStyles.caption),
                onTap: () => setState(() => _selectedUserId = m.id),
              );
            },
          )),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _selectedUserId == null ? null : () async {
                await ref.read(activityRepositoryProvider).assignActivity(widget.activityId, _selectedUserId!);
                ref.invalidate(dashboardProvider);
                if (mounted) context.go('/');
              },
              child: const Text('Confirmar asignación'),
            ),
          ),
        ]),
      ),
    );
  }
}
