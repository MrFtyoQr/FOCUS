import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/activity_status_colors.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/storage/local_prefs.dart';

// Provider local para la ruta de la foto de perfil
final _profilePhotoProvider = StateProvider<String?>((ref) => null);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider);
    final photoPath = ref.watch(_profilePhotoProvider);
    final scheme    = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);

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
                                    scheme.primary.withValues(alpha: 0.18),
                                backgroundImage: photoPath != null
                                    ? FileImage(File(photoPath))
                                    : null,
                                child: photoPath == null
                                    ? Text(
                                        user.firstName.isNotEmpty
                                            ? user.firstName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: scheme.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: scheme.surface, width: 2),
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
                          child: Text('Cambiar foto',
                              style: TextStyle(
                                  color: scheme.primary, fontSize: 13)),
                        ),
                        Text(
                          user.fullName,
                          style: AppTextStyles.heading1
                              .copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: AppTextStyles.bodySecondary
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(user.role.label,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor:
                              scheme.primary.withValues(alpha: 0.12),
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

                  ListTile(
                    leading: Icon(Icons.palette_outlined, color: scheme.primary),
                    title: const Text('Apariencia'),
                    subtitle: Text(_themeModeLabel(themeMode)),
                    trailing: const Icon(Icons.chevron_right),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _showThemePicker(context, ref),
                  ),
                  const SizedBox(height: 4),

                  // ── Acciones ──────────────────────────────────────────
                  ListTile(
                    leading: Icon(Icons.lock_outline, color: scheme.primary),
                    title: const Text('Seguridad y acceso'),
                    trailing: const Icon(Icons.chevron_right),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.go('/profile/security'),
                  ),
                  const SizedBox(height: 24),

                  // ── Cerrar sesión (tono «Pendientes») ─────────────────
                  SizedBox(
                    width: double.infinity,
                    child: Builder(
                      builder: (ctx) {
                        final pendientes =
                            EstadoActividadColors.forEstadoConContexto(
                          ctx,
                          ActivityStatus.pendientes,
                        );
                        return OutlinedButton.icon(
                          onPressed: () async {
                            final confirmed =
                                await _confirmLogout(ctx);
                            if (confirmed && ctx.mounted) {
                              await ref.read(authProvider.notifier).logout();
                              if (ctx.mounted) ctx.go('/login');
                            }
                          },
                          icon: Icon(Icons.logout, color: pendientes),
                          label: Text(
                            'Cerrar sesión',
                            style: TextStyle(color: pendientes),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize:
                                const Size(double.infinity, 50),
                            side: BorderSide(color: pendientes),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  static String _themeModeLabel(ThemeMode m) => switch (m) {
        ThemeMode.light => 'Claro',
        ThemeMode.dark => 'Oscuro',
        _ => 'Según el sistema',
      };

  Future<void> _showThemePicker(BuildContext context, WidgetRef ref) async {
    final surface = Theme.of(context).colorScheme.surface;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('Según el sistema'),
              onTap: () async {
                await LocalPrefs.instance.setThemeMode(ThemeMode.system);
                ref.read(themeModeProvider.notifier).state = ThemeMode.system;
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text('Claro'),
              onTap: () async {
                await LocalPrefs.instance.setThemeMode(ThemeMode.light);
                ref.read(themeModeProvider.notifier).state = ThemeMode.light;
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Oscuro'),
              onTap: () async {
                await LocalPrefs.instance.setThemeMode(ThemeMode.dark);
                ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
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
    final scheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: scheme.surface,
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
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: scheme.primary),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: scheme.primary),
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
    final pendientes = EstadoActividadColors.forEstadoConContexto(
      context,
      ActivityStatus.pendientes,
    );
    final onPendientes =
        ThemeData.estimateBrightnessForColor(pendientes) == Brightness.light
            ? const Color(0xFF4A1518)
            : Colors.white;

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
              backgroundColor: pendientes,
              foregroundColor: onPendientes,
            ),
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(
        label,
        style: AppTextStyles.caption
            .copyWith(color: scheme.onSurfaceVariant),
      ),
      subtitle: Text(
        value,
        style: AppTextStyles.body.copyWith(color: scheme.onSurface),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
