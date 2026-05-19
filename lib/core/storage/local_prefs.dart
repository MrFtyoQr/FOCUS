import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  LocalPrefs._();
  static final LocalPrefs instance = LocalPrefs._();

  static const _onboardingKey    = 'onboarding_completed';
  static const _biometricEnabled = 'biometric_enabled';
  static const _themeModeKey     = 'theme_mode';

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  Future<bool> isOnboardingCompleted() async =>
      (await _prefs).getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingCompleted() async =>
      (await _prefs).setBool(_onboardingKey, true);

  Future<void> clearOnboarding() async =>
      (await _prefs).remove(_onboardingKey);

  Future<bool> isBiometricEnabled() async =>
      (await _prefs).getBool(_biometricEnabled) ?? false;

  Future<void> setBiometricEnabled(bool value) async =>
      (await _prefs).setBool(_biometricEnabled, value);

  /// 0 = sistema, Claro = 1, Oscuro = 2. Sin valor guardado → oscuro (look por defecto de la app).
  Future<ThemeMode> getThemeMode() async {
    final v = (await _prefs).getInt(_themeModeKey);
    if (v == null) return ThemeMode.dark;
    return switch (v) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final v = switch (mode) {
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
      _ => 0,
    };
    await (await _prefs).setInt(_themeModeKey, v);
  }
}
