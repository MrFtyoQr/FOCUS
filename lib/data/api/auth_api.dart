import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Respuesta de login (alineada al backend).
class LoginResponse {
  final String accessToken;
  final String tokenType;
  final UserResponse user;
  final String? refreshToken;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
    this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: UserResponse.fromJson(json['user'] as Map<String, dynamic>),
      refreshToken: json['refresh_token'] as String?,
    );
  }
}

class UserResponse {
  final int id;
  final String email;
  final String nombre;
  final String? apellido;
  final bool activo;
  final String? fechaCreacion;
  /// Rol global (según backend): SUPER_ADMIN, ADMIN, PROPIETARIO, MIEMBRO, INVITADO
  final String? rol;

  UserResponse({
    required this.id,
    required this.email,
    required this.nombre,
    this.apellido,
    required this.activo,
    this.fechaCreacion,
    this.rol,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String?,
      activo: json['activo'] as bool? ?? true,
      fechaCreacion: json['fecha_creacion'] as String?,
      rol: json['rol'] as String?,
    );
  }

  String get displayName => apellido != null ? '$nombre $apellido' : nombre;
}

/// Llamadas de autenticación al backend.
class AuthApi {
  AuthApi._();
  static final AuthApi _instance = AuthApi._();
  factory AuthApi() => _instance;

  final ApiClient _client = ApiClient();

  /// POST /auth/login
  Future<LoginResponse> login({
    required String email,
    required String password,
    String? deviceFingerprint,
  }) async {
    final dio = _client.dio;
    final response = await dio.post<Map<String, dynamic>>(
      'auth/login',
      data: {
        'email': email,
        'password': password,
        if (deviceFingerprint != null && deviceFingerprint.isNotEmpty) 'device_fingerprint': deviceFingerprint,
      },
    );
    if (response.data == null) throw DioException(requestOptions: response.requestOptions, message: 'Sin datos');
    return LoginResponse.fromJson(response.data!);
  }

  /// POST /auth/register
  Future<UserResponse> register({
    required String email,
    required String password,
    required String nombre,
    String? apellido,
  }) async {
    final dio = _client.dio;
    // [REG_DEBUG] TODO: retirar cuando se localice el retraso
    final baseUrl = dio.options.baseUrl;
    final fullUrl = '$baseUrl/auth/register';
    final sw = Stopwatch()..start();
    debugPrint('[REG_DEBUG] AuthApi.register: enviando POST $fullUrl ${DateTime.now().toIso8601String()}');
    try {
      final response = await dio.post<Map<String, dynamic>>(
        'auth/register',
        data: {
          'email': email,
          'password': password,
          'nombre': nombre,
          if (apellido != null) 'apellido': apellido,
        },
      );
      sw.stop();
      debugPrint('[REG_DEBUG] AuthApi.register: respuesta OK en ${sw.elapsedMilliseconds}ms status=${response.statusCode}');
      if (response.data == null) throw DioException(requestOptions: response.requestOptions, message: 'Sin datos');
      return UserResponse.fromJson(response.data!);
    } catch (e, st) {
      sw.stop();
      debugPrint('[REG_DEBUG] AuthApi.register: fallo tras ${sw.elapsedMilliseconds}ms: $e');
      if (e is DioException) {
        debugPrint('[REG_DEBUG] AuthApi.register: DioException.type=${e.type} error=${e.error}');
      }
      debugPrint('[REG_DEBUG] AuthApi.register: stack $st');
      rethrow;
    }
  }

  /// GET /users/me — usuario actual (incluye rol actualizado).
  Future<UserResponse> getMe() async {
    final response = await _client.dio.get<Map<String, dynamic>>('users/me');
    if (response.data == null) throw DioException(requestOptions: response.requestOptions, message: 'Sin datos');
    return UserResponse.fromJson(response.data!);
  }

  /// POST /auth/logout (requiere Bearer)
  Future<void> logout() async {
    await _client.dio.post('auth/logout');
  }
}
