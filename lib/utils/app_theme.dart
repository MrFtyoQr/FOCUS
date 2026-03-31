import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema de la aplicación optimizado para productividad
class AppTheme {
  /// Azul base para acciones primarias (botones rellenos, FAB, enlaces fuertes, etc.).
  static const Color accentBlue = Color(0xFF2563EB);

  /// Superficie clara: nada de negro puro sobre blanco puro.
  static const Color _lightSurface = Color(0xFFE9ECF2);
  static const Color _lightOnSurface = Color(0xFF1C1C1E);
  static const Color _lightSurfaceContainer = Color(0xFFE0E4EB);

  /// Oscuro: nada de blanco puro sobre negro puro.
  static const Color _darkSurface = Color(0xFF17181B);
  static const Color _darkOnSurface = Color(0xFFE8E8EC);
  static const Color _darkSurfaceContainer = Color(0xFF343741);

  static InputDecorationTheme _inputDecorationTheme(ColorScheme scheme, {required bool isDark}) {
    final borderRadius = BorderRadius.circular(18);
    final baseBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: isDark
            ? scheme.onSurface.withValues(alpha: 0.48)
            : scheme.onSurface.withValues(alpha: 0.28),
        width: 1.2,
      ),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.22)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle: TextStyle(
        color: scheme.onSurface.withValues(alpha: isDark ? 0.62 : 0.54),
      ),
      labelStyle: TextStyle(
        color: scheme.onSurface.withValues(alpha: isDark ? 0.82 : 0.72),
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: scheme.primary.withValues(alpha: isDark ? 0.95 : 0.9),
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: scheme.onSurface.withValues(alpha: isDark ? 0.78 : 0.66),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: scheme.primary.withValues(alpha: isDark ? 0.9 : 0.78),
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: scheme.error.withValues(alpha: 0.82),
          width: 1.4,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: scheme.error.withValues(alpha: 0.9),
          width: 1.6,
        ),
      ),
    );
  }

  /// Pesos: 400 cuerpo, 500 subtítulos, 600 títulos.
  static TextTheme _interTextThemeWithWeights(TextTheme base) {
    TextStyle w400(TextStyle? s) =>
        GoogleFonts.inter(textStyle: s, fontWeight: FontWeight.w400);
    TextStyle w500(TextStyle? s) =>
        GoogleFonts.inter(textStyle: s, fontWeight: FontWeight.w500);
    TextStyle w600(TextStyle? s) =>
        GoogleFonts.inter(textStyle: s, fontWeight: FontWeight.w600);

    return base.copyWith(
      displayLarge: w600(base.displayLarge),
      displayMedium: w600(base.displayMedium),
      displaySmall: w600(base.displaySmall),
      headlineLarge: w600(base.headlineLarge),
      headlineMedium: w600(base.headlineMedium),
      headlineSmall: w600(base.headlineSmall),
      titleLarge: w600(base.titleLarge),
      titleMedium: w600(base.titleMedium),
      titleSmall: w500(base.titleSmall),
      bodyLarge: w400(base.bodyLarge),
      bodyMedium: w400(base.bodyMedium),
      bodySmall: w400(base.bodySmall),
      labelLarge: w500(base.labelLarge),
      labelMedium: w500(base.labelMedium),
      labelSmall: w400(base.labelSmall),
    );
  }

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: accentBlue,
      brightness: Brightness.light,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      surfaceContainerHighest: _lightSurfaceContainer,
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _lightSurface,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: scheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: _lightSurface,
        foregroundColor: _lightOnSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _lightOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: scheme.surfaceContainerLow,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(scheme, isDark: false),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );

    final interTheme = GoogleFonts.interTextTheme(theme.textTheme);
    return theme.copyWith(
      textTheme: _interTextThemeWithWeights(interTheme).apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: accentBlue,
      brightness: Brightness.dark,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      surfaceContainerHighest: _darkSurfaceContainer,
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkSurface,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: scheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: _darkSurface,
        foregroundColor: _darkOnSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _darkOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(scheme, isDark: true),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );

    final interTheme = GoogleFonts.interTextTheme(theme.textTheme);
    return theme.copyWith(
      textTheme: _interTextThemeWithWeights(interTheme).apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}
