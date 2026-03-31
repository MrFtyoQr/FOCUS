import 'package:flutter/material.dart';

import '../models/models.dart';

/// Colores pasteles por estado (badges, chips, barras, slugs de listado).
abstract final class EstadoActividadColors {
  // Light mode (solicitado por usuario)
  static const Color bandejaLight = Color(0xFF9AA3B2);
  static const Color hoyLight = Color(0xFF4F7FD1);
  static const Color mananaLight = Color(0xFFE78A4E);
  static const Color programadoLight = Color(0xFF8C6BCB);
  static const Color pendientesLight = Color(0xFFD96B6B);
  static const Color completadaLight = Color(0xFF4DAA72);

  // Dark mode (se mantiene pastel)
  static const Color bandejaDark = Color(0xFFB4B8C4);
  static const Color hoyDark = Color(0xFF8FB4E0);
  static const Color mananaDark = Color(0xFFE8C4A4);
  static const Color programadoDark = Color(0xFFC4B8E8);
  static const Color pendientesDark = Color(0xFFE0A8B8);
  static const Color completadaDark = Color(0xFF9BC9A8);

  // Compatibilidad con referencias existentes sin contexto.
  static const Color pendientes = pendientesDark;
  static const Color completada = completadaDark;

  static Color forEstado(EstadoActividad estado, {Brightness brightness = Brightness.dark}) {
    final isLight = brightness == Brightness.light;
    switch (estado) {
      case EstadoActividad.bandeja:
        return isLight ? bandejaLight : bandejaDark;
      case EstadoActividad.hoy:
        return isLight ? hoyLight : hoyDark;
      case EstadoActividad.manana:
        return isLight ? mananaLight : mananaDark;
      case EstadoActividad.programado:
        return isLight ? programadoLight : programadoDark;
      case EstadoActividad.pendientes:
        return isLight ? pendientesLight : pendientesDark;
      case EstadoActividad.completada:
        return isLight ? completadaLight : completadaDark;
    }
  }

  static Color forEstadoConContexto(BuildContext context, EstadoActividad estado) {
    return forEstado(estado, brightness: Theme.of(context).brightness);
  }
}
