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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Perfil')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              Center(child: CircleAvatar(
                radius: 44, backgroundColor: AppColors.purple.withValues(alpha: 0.2),
                child: Text(
                  '${user.firstName[0]}${user.lastName.isNotEmpty ? user.lastName[0] : ''}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.purpleLight),
                ),
              )),
              const SizedBox(height: 16),
              Text(user.fullName, style: AppTextStyles.heading1, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(user.email, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(user.role.label, style: const TextStyle(color: AppColors.purpleLight, fontSize: 12, fontWeight: FontWeight.w600)),
              )),
              if (user.areaName != null) ...[
                const SizedBox(height: 4),
                Text('Área: ${user.areaName}', style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 32),
              const Divider(color: AppColors.surfaceBorder),
              ListTile(
                leading: const Icon(Icons.security_outlined, color: AppColors.textSecondary),
                title: const Text('Seguridad (biometría / PIN)'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                onTap: () => context.go('/profile/security'),
              ),
              const Divider(color: AppColors.surfaceBorder),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
              ),
            ]),
    );
  }
}
