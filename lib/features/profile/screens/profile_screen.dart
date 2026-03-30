import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + nombre
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.purple.withValues(alpha: 0.2),
                          child: Text(
                            user.firstName.isNotEmpty
                                ? user.firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(user.fullName,
                            style: AppTextStyles.heading1),
                        const SizedBox(height: 4),
                        Text(user.email,
                            style: AppTextStyles.bodySecondary),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(user.role.label,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor:
                              AppColors.purple.withValues(alpha: 0.15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Info de cuenta
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Correo',
                    value: user.email,
                  ),
                  if (user.areaName != null)
                    _InfoTile(
                      icon: Icons.business_outlined,
                      label: 'Área',
                      value: user.areaName!,
                    ),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Rol',
                    value: user.role.label,
                  ),
                  const SizedBox(height: 32),
                  // Cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout, color: AppColors.red),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: AppColors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: AppColors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.purple),
      title: Text(label,
          style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary)),
      subtitle: Text(value, style: AppTextStyles.body),
      contentPadding: EdgeInsets.zero,
    );
  }
}
