import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user.dart';

/// Datos de la invitación devueltos por el backend al verificar un código.
class InviteInfo {
  final String  role;
  final String? areaName;
  final String? expiresAt;

  const InviteInfo({
    required this.role,
    this.areaName,
    this.expiresAt,
  });

  String get roleLabel => switch (role) {
    'super_admin' => 'Super Admin',
    'admin_area'  => 'Administrador de Área',
    _             => 'Trabajador',
  };

  factory InviteInfo.fromJson(Map<String, dynamic> json) => InviteInfo(
    role:      json['role']      as String? ?? '',
    areaName:  json['area_name'] as String?,
    expiresAt: json['expires_at'] as String?,
  );
}

/// Convierte un [DioException] en un mensaje legible para el usuario.
String _parseError(DioException e, {String fallback = 'Error inesperado'}) {
  final data = e.response?.data;
  if (data is Map) {
    // Primer valor de error del mapa (detail, code, non_field_errors, etc.)
    final values = data.values.whereType<Object>().toList();
    if (values.isNotEmpty) {
      final first = values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
  }
  if (data is String && data.isNotEmpty) return data;
  return e.message ?? fallback;
}

class AuthRepository {
  final _api = ApiClient.instance;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    await SecureStorage.instance.saveTokens(
      access:  response.data['access']  as String,
      refresh: response.data['refresh'] as String,
    );
    return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  /// Verifica el código de invitación con el backend **antes** de mostrar el
  /// formulario de registro. Lanza [Exception] con mensaje legible si el código
  /// es inválido, expirado o ya fue usado.
  Future<InviteInfo> verifyInviteCode(String code) async {
    try {
      final response = await _api.post(
        ApiEndpoints.verifyInvite,
        data: {'code': code},
      );
      return InviteInfo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_parseError(e, fallback: 'Código inválido o expirado'));
    }
  }

  Future<UserModel> acceptInvitation({
    required String code,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      final response = await _api.post(ApiEndpoints.acceptInvite, data: {
        'code':       code,
        'email':      email,
        'first_name': firstName,
        'last_name':  lastName,
        'password':   password,
      });
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_parseError(e, fallback: 'No se pudo crear la cuenta'));
    }
  }

  Future<UserModel> getMe() async {
    final response = await _api.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      final refresh = await SecureStorage.instance.getRefreshToken();
      if (refresh != null) {
        await _api.post(ApiEndpoints.logout, data: {'refresh': refresh});
      }
    } catch (_) {
      // Si falla el logout en servidor, limpiamos local igualmente
    } finally {
      await SecureStorage.instance.clearAll();
    }
  }

  Future<void> enableBiometric(String deviceId) async {
    await _api.post(ApiEndpoints.biometricEnable, data: {'device_id': deviceId});
  }

  Future<void> disableBiometric() async {
    await _api.post(ApiEndpoints.biometricDisable);
  }

  Future<UserModel> biometricLogin({
    required String deviceId,
    required String refresh,
  }) async {
    final response = await _api.post(ApiEndpoints.biometricLogin, data: {
      'device_id': deviceId,
      'refresh':   refresh,
    });
    await SecureStorage.instance.saveTokens(
      access:  response.data['access']  as String,
      refresh: response.data['refresh'] as String,
    );
    return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<void> completeOnboarding() async {
    await _api.post(ApiEndpoints.onboardingComplete);
  }
}
