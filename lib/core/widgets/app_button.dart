import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = _background(scheme);
    final fg = _foreground(scheme);
    final child = isLoading
        ? SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                fg,
              ),
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                  Text(label,
                      style: AppTextStyles.button.copyWith(color: fg)),
                ],
              )
            : Text(label,
                style: AppTextStyles.button.copyWith(color: fg));

    return SizedBox(
      width: width ?? double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          side: variant == AppButtonVariant.ghost
              ? const BorderSide(color: AppColors.surfaceBorder)
              : null,
        ),
        child: child,
      ),
    );
  }

  Color _background(ColorScheme scheme) {
    switch (variant) {
      case AppButtonVariant.primary:
        return scheme.primary;
      case AppButtonVariant.secondary:
        return AppColors.surface;
      case AppButtonVariant.danger:
        return AppColors.red;
      case AppButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _foreground(ColorScheme scheme) {
    switch (variant) {
      case AppButtonVariant.primary:
        return scheme.onPrimary;
      case AppButtonVariant.secondary:
        return AppColors.textPrimary;
      case AppButtonVariant.danger:
        return Colors.white;
      case AppButtonVariant.ghost:
        return AppColors.textSecondary;
    }
  }
}
