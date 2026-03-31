import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  LocalPrefs._();
  static final LocalPrefs instance = LocalPrefs._();

  static const _onboardingKey    = 'onboarding_completed';
  static const _biometricEnabled = 'biometric_enabled';

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
}
