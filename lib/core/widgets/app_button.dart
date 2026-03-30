import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
    final child = isLoading
        ? SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _foreground,
              ),
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: _foreground),
                  const SizedBox(width: 8),
                  Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _foreground)),
                ],
              )
            : Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _foreground));

    return SizedBox(
      width: width ?? double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _background,
          foregroundColor: _foreground,
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

  Color get _background {
    switch (variant) {
      case AppButtonVariant.primary:   return AppColors.purple;
      case AppButtonVariant.secondary: return AppColors.surface;
      case AppButtonVariant.danger:    return AppColors.red;
      case AppButtonVariant.ghost:     return Colors.transparent;
    }
  }

  Color get _foreground {
    switch (variant) {
      case AppButtonVariant.primary:   return Colors.white;
      case AppButtonVariant.secondary: return AppColors.textPrimary;
      case AppButtonVariant.danger:    return Colors.white;
      case AppButtonVariant.ghost:     return AppColors.textSecondary;
    }
  }
}
