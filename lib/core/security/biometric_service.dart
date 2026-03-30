import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../storage/secure_storage.dart';
import '../storage/local_prefs.dart';

enum BiometricResult { success, failure, notAvailable, lockedOut }

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<BiometricResult> authenticate() async {
    try {
      final available = await isAvailable();
      if (!available) return BiometricResult.notAvailable;

      final authenticated = await _auth.authenticate(
        localizedReason: 'Confirma tu identidad para acceder',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return authenticated ? BiometricResult.success : BiometricResult.failure;
    } on PlatformException catch (e) {
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return BiometricResult.lockedOut;
      }
      return BiometricResult.failure;
    }
  }

  Future<bool> validatePin(String inputPin) async {
    final savedPin = await SecureStorage.instance.getPin();
    return savedPin != null && savedPin == inputPin;
  }

  Future<void> savePin(String pin) async {
    await SecureStorage.instance.savePin(pin);
    await LocalPrefs.instance.setBiometricEnabled(true);
  }

  Future<bool> unlock() async {
    final biometricEnabled   = await LocalPrefs.instance.isBiometricEnabled();
    final biometricAvailable = await isAvailable();

    if (biometricAvailable && biometricEnabled) {
      final result = await authenticate();
      if (result == BiometricResult.success) return true;
      if (result == BiometricResult.lockedOut) return false;
    }
    return false;
  }
}
