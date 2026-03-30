import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/team_provider.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/responsive.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider);
    final isDesktop    = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(teamMembersProvider),
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No se pudo cargar el equipo'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(teamMembersProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (members) => members.isEmpty
            ? const EmptyState(
                icon: Icons.group_outlined,
                title: 'Sin miembros',
                subtitle: 'Invita personas a tu equipo para colaborar.',
              )
            : ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: 12,
                ),
                itemCount: members.length,
                itemBuilder: (_, i) {
                  final m = members[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          m.firstName.isNotEmpty
                              ? m.firstName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(m.fullName),
                      subtitle: Text(m.email),
                      trailing: Chip(
                        label: Text(
                          m.role.label,
                          style: const TextStyle(fontSize: 11),
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
