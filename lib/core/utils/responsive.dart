import 'package:flutter/material.dart';

/// Utilidades para diseño responsivo
class Responsive {
  /// Breakpoint para tablets (600dp)
  static const double tabletBreakpoint = 600;

  /// Breakpoint para desktop (1200dp)
  static const double desktopBreakpoint = 1200;

  /// Detecta si es tablet o desktop
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Detecta si es desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Detecta si está en modo horizontal
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Obtiene el número de columnas según el tamaño de pantalla
  static int getColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return 4;
    } else if (width >= tabletBreakpoint) {
      return 2;
    }
    return 1;
  }

  /// Obtiene el padding horizontal según el tamaño de pantalla
  static double getHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) {
      return 48.0;
    } else if (isTablet(context)) {
      return 32.0;
    }
    return 16.0;
  }

  /// Obtiene el ancho máximo del contenido
  static double? getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1400;
    } else if (isTablet(context)) {
      return 1200;
    }
    return null;
  }
}
