import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/config.dart';
import '../../core/security/secure_storage.dart';
import '../../core/security/device_fingerprint.dart';

/// Interceptor de logs (solo en debug): URL, método, status, errores.
class _ApiLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri.toString();
    debugPrint('[API] → ${options.method} $uri');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final uri = response.requestOptions.uri.toString();
    debugPrint('[API] ← ${response.statusCode} ${response.requestOptions.method} $uri');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final uri = err.requestOptions.uri.toString();
    final status = err.response?.statusCode;
    final msg = err.message ?? '';
    final detail = err.response?.data is Map ? (err.response!.data as Map)['detail']?.toString() : null;
    debugPrint('[API] ✗ ERROR ${status ?? '--'} ${err.requestOptions.method} $uri');
    debugPrint('[API]    message: $msg${detail != null ? ' | detail: $detail' : ''}');
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      debugPrint('[API]    (timeout: comprueba IP, que el backend esté en marcha y en la misma red)');
    }
    if (err.type == DioExceptionType.connectionError) {
      debugPrint('[API]    (sin conexión: comprueba URL, firewall, que el servidor escuche en esa IP)');
    }
    handler.next(err);
  }
}

/// Cliente HTTP con interceptor: Bearer + X-Device-Fingerprint.
/// En 401: intentar refresh (si existe endpoint); si falla, cerrar sesión.
class ApiClient {
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final SecureStorage _storage = SecureStorage();
  final DeviceFingerprint _fingerprint = DeviceFingerprint();
  bool _isRefreshing = false;

  Dio get dio => _dio;

  void init() {
    final baseUrl = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl
        : '${AppConfig.apiBaseUrl}/';
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));
    if (kDebugMode) {
      debugPrint('[API] ApiClient.init baseUrl=$baseUrl');
    }
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));
    if (kDebugMode) {
      _dio.interceptors.add(_ApiLogInterceptor());
    }
  }

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    final fingerprint = await _fingerprint.getOrCreateFingerprint();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['X-Device-Fingerprint'] = fingerprint;
    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  Future<void> _onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _tryRefresh();
        if (refreshed) {
          final token = await _storage.getAccessToken();
          final fingerprint = await _fingerprint.getOrCreateFingerprint();
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          err.requestOptions.headers['X-Device-Fingerprint'] = fingerprint;
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (_) {}
      _isRefreshing = false;
      await _storage.clearSession();
      handler.reject(err);
      return;
    }
    _isRefreshing = false;
    handler.next(err);
  }

  /// Renueva el access_token usando refresh_token (POST /auth/refresh).
  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      // No usar interceptor de Bearer para esta petición (aún no tenemos token válido)
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {
            'X-Device-Fingerprint': await _fingerprint.getOrCreateFingerprint(),
          },
        ),
      );
      if (response.data == null) return false;
      final accessToken = response.data!['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) return false;
      await _storage.setAccessToken(accessToken);
      final newRefresh = response.data!['refresh_token'] as String?;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _storage.setRefreshToken(newRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
