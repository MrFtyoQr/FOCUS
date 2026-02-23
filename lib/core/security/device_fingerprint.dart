import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../constants.dart';
import 'secure_storage.dart';

/// Genera un ID estable por instalación (device_fingerprint).
/// Se hashea con SHA-256 para no enviar datos crudos al backend.
class DeviceFingerprint {
  DeviceFingerprint._();
  static final DeviceFingerprint _instance = DeviceFingerprint._();
  factory DeviceFingerprint() => _instance;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final SecureStorage _storage = SecureStorage();

  /// Obtener o crear fingerprint: lee de secure storage; si no existe, genera, guarda y devuelve.
  Future<String> getOrCreateFingerprint() async {
    final existing = await _storage.getDeviceFingerprint();
    if (existing != null && existing.isNotEmpty) return existing;

    final raw = await _buildRawFingerprint();
    final fingerprint = _hash(raw);
    await _storage.setDeviceFingerprint(fingerprint);
    return fingerprint;
  }

  String _hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String> _buildRawFingerprint() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = await _deviceInfo.androidInfo;
      final parts = [
        android.id,
        android.model,
        android.device,
        android.brand,
      ];
      return parts.where((e) => e.isNotEmpty).join('|');
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = await _deviceInfo.iosInfo;
      final parts = [
        ios.identifierForVendor ?? '',
        ios.model,
        ios.systemVersion,
      ];
      return parts.where((e) => e.isNotEmpty).join('|');
    }
    // Web / desktop: usar un identificador fijo por “instalación” (no hay device id nativo)
    return '${DateTime.now().millisecondsSinceEpoch}_desktop';
  }
}
