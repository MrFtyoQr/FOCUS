import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// Provider local para la ruta de la foto de perfil
final _profilePhotoProvider = StateProvider<String?>((ref) => null);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider);
    final photoPath = ref.watch(_profilePhotoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ────────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _pickPhoto(context, ref),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor:
                                    AppColors.purple.withValues(alpha: 0.2),
                                backgroundImage: photoPath != null
                                    ? FileImage(File(photoPath))
                                    : null,
                                child: photoPath == null
                                    ? Text(
                                        user.firstName.isNotEmpty
                                            ? user.firstName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.purple,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.background, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () => _pickPhoto(context, ref),
                          child: const Text('Cambiar foto',
                              style: TextStyle(
                                  color: AppColors.purple, fontSize: 13)),
                        ),
                        Text(user.fullName, style: AppTextStyles.heading1),
                        const SizedBox(height: 4),
                        Text(user.email, style: AppTextStyles.bodySecondary),
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
                  const SizedBox(height: 8),

                  // ── Info ──────────────────────────────────────────────
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
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),

                  // ── Acciones ──────────────────────────────────────────
                  ListTile(
                    leading: const Icon(Icons.lock_outline,
                        color: AppColors.purple),
                    title: const Text('Seguridad y acceso'),
                    trailing: const Icon(Icons.chevron_right),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.go('/profile/security'),
                  ),
                  const SizedBox(height: 24),

                  // ── Cerrar sesión ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed =
                            await _confirmLogout(context);
                        if (confirmed && context.mounted) {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout,
                          color: AppColors.red),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: AppColors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size(double.infinity, 50),
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

  Future<void> _pickPhoto(BuildContext context, WidgetRef ref) async {
    final source = await _showSourceDialog(context);
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    ref.read(_profilePhotoProvider.notifier).state = picked.path;
  }

  Future<ImageSource?> _showSourceDialog(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.purple),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.purple),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content:
            const Text('¿Seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    return result ?? false;
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
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.purple),
        title: Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        subtitle: Text(value, style: AppTextStyles.body),
        contentPadding: EdgeInsets.zero,
      );
}
