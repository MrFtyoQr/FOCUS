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
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API] → ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[API] ← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status  = err.response?.statusCode ?? '--';
    final detail  = err.response?.data is Map ? (err.response!.data as Map)['detail'] : null;
    debugPrint('[API] ✗ $status ${err.requestOptions.method} ${err.requestOptions.uri}${detail != null ? ' | $detail' : ''}');
    handler.next(err);
  }
}
