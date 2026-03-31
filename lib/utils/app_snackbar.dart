import 'package:flutter/material.dart';

import 'paleta_pasteles.dart';

/// SnackBars alineados a la paleta pastel (sin primarios Material ni blanco/negro puros en primer plano).
abstract final class AppSnackBar {
  static const TextStyle _estiloExito = TextStyle(
    color: PaletaPasteles.snackExitoTexto,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle _estiloAviso = TextStyle(
    color: PaletaPasteles.snackAvisoTexto,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle _estiloError = TextStyle(
    color: PaletaPasteles.snackErrorTexto,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle _estiloInfo = TextStyle(
    color: PaletaPasteles.snackInfoTexto,
    fontWeight: FontWeight.w600,
  );

  static SnackBar exito(
    String mensaje, {
    String? etiquetaAccion,
    VoidCallback? alAccion,
  }) {
    return SnackBar(
      backgroundColor: PaletaPasteles.snackExitoFondo,
      duration: const Duration(seconds: 4),
      content: Text(mensaje, style: _estiloExito),
      action: etiquetaAccion != null && alAccion != null
          ? SnackBarAction(
              label: etiquetaAccion,
              textColor: PaletaPasteles.snackExitoTexto,
              onPressed: alAccion,
            )
          : null,
    );
  }

  static SnackBar aviso(String mensaje) {
    return SnackBar(
      backgroundColor: PaletaPasteles.snackAvisoFondo,
      duration: const Duration(seconds: 4),
      content: Text(mensaje, style: _estiloAviso),
    );
  }

  static SnackBar error(String mensaje) {
    return SnackBar(
      backgroundColor: PaletaPasteles.snackErrorFondo,
      duration: const Duration(seconds: 5),
      content: Text(mensaje, style: _estiloError),
    );
  }

  /// Mensajes neutros (p. ej. errores genéricos sin tono “alerta roja”).
  static SnackBar info(String mensaje) {
    return SnackBar(
      backgroundColor: PaletaPasteles.snackInfoFondo,
      duration: const Duration(seconds: 4),
      content: Text(mensaje, style: _estiloInfo),
    );
  }
}
