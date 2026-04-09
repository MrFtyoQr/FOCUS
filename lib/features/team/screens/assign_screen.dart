import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/assign_candidates.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/data/activity_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/team_provider.dart';

class AssignScreen extends ConsumerStatefulWidget {
  final String activityId;
  const AssignScreen({super.key, required this.activityId});

  @override
  ConsumerState<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends ConsumerState<AssignScreen> {
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersListProvider);
    final me = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar actividad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/team'),
        ),
      ),
      body: workersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('No se pudieron cargar los trabajadores')),
        data: (workers) {
          final members = workersForAssignmentPicker(
            workersFromApi: workers,
            currentUser: me,
          );
          if (members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  me?.isAdminArea == true
                      ? 'No hay trabajadores en tu área para asignar'
                      : 'No hay personas disponibles para asignar',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (_, i) {
                  final m = members[i];
                  final selected = _selectedUserId == m.id;
                  return ListTile(
                    leading: Radio<String>(
                      value: m.id,
                      // ignore: deprecated_member_use
                      groupValue: _selectedUserId ?? '',
                      // ignore: deprecated_member_use
                      onChanged: (v) => setState(() => _selectedUserId = v),
                    ),
                    title: Text(m.fullName),
                    subtitle: Text(m.role.label),
                    selected: selected,
                    onTap: () => setState(() => _selectedUserId = m.id),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _selectedUserId == null
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(activityRepositoryProvider)
                              .assignActivity(
                                widget.activityId, _selectedUserId!);
                          ref.invalidate(dashboardProvider);
                          if (context.mounted) context.go('/');
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              AppSnackBar.error(messageFromAssignApiError(e)),
                            );
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirmar asignación'),
              ),
            ),
          ],
        );
        },
      ),
    );
  }
}
