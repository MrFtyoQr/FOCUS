import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Desbloqueo de la app con biometría (huella/Face ID) o PIN/patrón del dispositivo.
/// Requiere: iOS → NSFaceIDUsageDescription en Info.plist; Android → USE_BIOMETRIC en AndroidManifest.
class LocalAuth {
  LocalAuth._();
  static final LocalAuth _instance = LocalAuth._();
  factory LocalAuth() => _instance;

  final LocalAuthentication _auth = LocalAuthentication();

  /// Comprobar si el dispositivo soporta biometría.
  Future<bool> canCheckBiometrics() => _auth.canCheckBiometrics;

  /// Comprobar si el dispositivo permite autenticación (biometría o PIN/patrón).
  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  /// Listar tipos de biometría disponibles.
  Future<List<BiometricType>> getAvailableBiometrics() => _auth.getAvailableBiometrics();

  /// Autenticar al usuario (biometría o PIN/patrón del dispositivo).
  /// Permite fallback a PIN si biometricOnly es false (recomendado para que el usuario pueda desbloquear siempre).
  Future<bool> authenticate({
    String reason = 'Desbloquea la app para continuar',
    bool useErrorDialogs = true,
    bool biometricOnly = false,
  }) async {
    try {
      final supported = await isDeviceSupported();
      if (!supported) {
        if (kDebugMode) debugPrint('LocalAuth: dispositivo no soporta autenticación local');
        return false;
      }
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: true,
          biometricOnly: biometricOnly,
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('LocalAuth.authenticate error: $e');
        debugPrint('LocalAuth.authenticate stack: $st');
      }
      return false;
    }
  }

  /// True si hay huella, Face ID o el dispositivo permite PIN/patrón para desbloquear.
  Future<bool> hasBiometricsAvailable() async {
    try {
      if (!await isDeviceSupported()) return false;
      final canCheck = await canCheckBiometrics();
      if (canCheck) {
        final list = await getAvailableBiometrics();
        if (list.isNotEmpty) return true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
