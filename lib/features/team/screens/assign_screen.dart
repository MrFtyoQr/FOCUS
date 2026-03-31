import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/team_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

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
    final membersAsync = ref.watch(teamMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar actividad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/team'),
        ),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('No se pudieron cargar los miembros')),
        data: (members) => Column(
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
                        await ref
                            .read(activityRepositoryProvider)
                            .assignActivity(
                                widget.activityId, _selectedUserId!);
                        ref.invalidate(dashboardProvider);
                        if (context.mounted) context.go('/');
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
        ),
      ),
    );
  }
}
