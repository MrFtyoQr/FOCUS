import 'package:flutter/material.dart';

import '../utils/activity_status_colors.dart';

class AppColors {
  AppColors._();

  // Fondos
  static const background    = Color(0xFF141418);
  static const surface       = Color(0xFF1E1E28);
  static const surfaceBorder = Color(0xFF2E2E3A);

  // Texto
  static const textPrimary   = Color(0xFFE8E6E0);
  static const textSecondary = Color(0xFF888780);
  static const textTertiary  = Color(0xFF5F5E5A);

  /// Mismos tonos que el estado «Hoy» ([EstadoActividadColors]).
  static const primaryLight = EstadoActividadColors.hoyLight;
  static const primaryDark = EstadoActividadColors.hoyDark;

  /// Texto e iconos sobre [primaryDark] (contraste sobre el azul pastel de Hoy).
  static const onPrimaryDark = Color(0xFF08202F);

  static const teal     = Color(0xFF1D9E75);
  static const tealDark = Color(0xFF0F6E56);

  static const amber     = Color(0xFFEF9F27);
  static const amberDark = Color(0xFF854F0B);

  static const blue     = Color(0xFF378ADD);
  static const blueDark = Color(0xFF185FA5);

  static const red    = Color(0xFFE24B4A);
  static const green  = Color(0xFF1D9E75);
  static const yellow = amber;

  // Estados de actividad
  static Color statusColor(String status) {
    switch (status) {
      case 'hoy':        return teal;
      case 'manana':     return amber;
      case 'programado': return blue;
      case 'pendientes': return red;
      case 'completada': return green;
      default:           return textSecondary;
    }
  }
}
