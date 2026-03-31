import 'package:flutter/material.dart';

/// Tonos suaves para UI que debe alinearse con Productividad / estados (sin primarios Material vivos).
abstract final class PaletaPasteles {
  /// Light mode
  static const Color fechaUrgenteLight = Color(0xFFE78A4E);
  static const Color fechaNormalLight = Color(0xFF4F7FD1);

  /// Dark mode (pastel)
  static const Color fechaUrgenteDark = Color(0xFFE8C4A0);
  static const Color fechaNormalDark = Color(0xFFA8B4C8);

  /// Misma secuencia que el diálogo «Nuevo proyecto»: azul → índigo suave.
  static const List<Color> coloresProyectoLight = [
    Color(0xFF4F7FD1),
    Color(0xFF4DAA72),
    Color(0xFFE78A4E),
    Color(0xFF8C6BCB),
    Color(0xFFD96B6B),
    Color(0xFF3AAFA9),
    Color(0xFF7A8AA0),
  ];

  static const List<Color> coloresProyectoDark = [
    Color(0xFF8FB4E0),
    Color(0xFF9BC9A8),
    Color(0xFFE8C4A4),
    Color(0xFFC4B8E8),
    Color(0xFFE0A8B8),
    Color(0xFFA8D7D0),
    Color(0xFFB8C3D8),
  ];

  static List<Color> coloresProyecto(Brightness brightness) =>
      brightness == Brightness.light ? coloresProyectoLight : coloresProyectoDark;

  static Color proyectoPredeterminado(Brightness brightness) =>
      coloresProyecto(brightness).first;

  static Color? _parseHexColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return null;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }

  static int? _proyectoColorIndex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    for (var i = 0; i < coloresProyectoLight.length; i++) {
      final lightRgb = coloresProyectoLight[i].toARGB32() & 0x00FFFFFF;
      if (rgb == lightRgb) return i;
    }
    for (var i = 0; i < coloresProyectoDark.length; i++) {
      final darkRgb = coloresProyectoDark[i].toARGB32() & 0x00FFFFFF;
      if (rgb == darkRgb) return i;
    }
    return null;
  }

  /// Mapea un color de proyecto guardado al equivalente por modo (light/dark).
  /// Si no pertenece a la paleta, devuelve el color original.
  static Color proyectoColorByMode(
    String? colorHex,
    Brightness brightness,
  ) {
    final parsed = _parseHexColor(colorHex);
    if (parsed == null) return proyectoPredeterminado(brightness);
    final index = _proyectoColorIndex(parsed);
    if (index == null) return parsed;
    return coloresProyecto(brightness)[index];
  }

  static String colorToHexRgb(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2)}';
  }

  /// SnackBars: pastelería clara sobre cualquier scaffold; texto oscuro suave (no #000 / #FFF).
  static const Color snackExitoFondo = Color(0xFF68B886);
  static const Color snackExitoTexto = Color(0xFF17341F);

  static const Color snackAvisoFondo = Color(0xFF9A7AD6);
  static const Color snackAvisoTexto = Color(0xFF1F1638);

  static const Color snackErrorFondo = Color(0xFFE07A7A);
  static const Color snackErrorTexto = Color(0xFF3E1515);

  static const Color snackInfoFondo = Color(0xFF5F8FDD);
  static const Color snackInfoTexto = Color(0xFF142943);

  /// `SlidableAction` Completar / Mover.
  static const Color slidableCompletarFondoLight = Color(0xFF4DAA72);
  static const Color slidableCompletarFondoDark = Color(0xFF9BC9A8);
  static const Color slidableCompletarPrimerPlano = Color(0xFF1E3229);

  static const Color slidableMoverFondoLight = Color(0xFF4F7FD1);
  static const Color slidableMoverFondoDark = Color(0xFF8FB4E0);
  static const Color slidableMoverPrimerPlano = Color(0xFF1E2C3D);

  static Color fechaUrgente(Brightness brightness) =>
      brightness == Brightness.light ? fechaUrgenteLight : fechaUrgenteDark;

  static Color fechaNormal(Brightness brightness) =>
      brightness == Brightness.light ? fechaNormalLight : fechaNormalDark;

  static Color slidableCompletarFondo(Brightness brightness) =>
      brightness == Brightness.light ? slidableCompletarFondoLight : slidableCompletarFondoDark;

  static Color slidableMoverFondo(Brightness brightness) =>
      brightness == Brightness.light ? slidableMoverFondoLight : slidableMoverFondoDark;
}
