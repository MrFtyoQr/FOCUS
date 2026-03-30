import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const heading1 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static const heading2 = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const heading3 = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );
  static const bodySecondary = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );
  static const caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary, letterSpacing: 0.04,
  );
  static const label = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: AppColors.textTertiary, letterSpacing: 0.06,
  );
}
