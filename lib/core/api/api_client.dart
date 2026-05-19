import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  void initialize() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    debugPrint('[API] Inicializando cliente → $baseUrl');
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(AuthInterceptor(_dio));
    if (kDebugMode) {
      _dio.interceptors.add(_LogInterceptor());
    }
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> upload(String path, FormData formData) =>
      _dio.post(path, data: formData);
}

class _LogInterceptor extends Interceptor {
  static String _truncate(Object? v, [int max = 300]) {
    if (v == null) return '';
    final s = v.toString();
    return s.length > max ? '${s.substring(0, max)}…' : s;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final body = options.data != null ? ' | body: ${_truncate(options.data)}' : '';
    debugPrint('[API] → ${options.method} ${options.uri}$body');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final path   = response.requestOptions.path;
    final method = response.requestOptions.method;
    final status = response.statusCode;
    debugPrint('[API] ← $status $method ${response.requestOptions.uri}');

    // Loguea body completo (truncado) para endpoints relevantes al debug actual.
    final _logBodyPaths = [
      '/users/invite',
      '/activities/',
      '/auth/me',
      '/auth/login',
    ];
    if (_logBodyPaths.any((p) => path.contains(p))) {
      debugPrint('[API] ← body: ${_truncate(response.data, 600)}');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode ?? '--';
    final uri    = err.requestOptions.uri;
    final method = err.requestOptions.method;
    final body   = err.response?.data != null ? _truncate(err.response!.data) : err.message ?? '';
    debugPrint('[API] ✗ $status $method $uri | $body');
    handler.next(err);
  }
}
