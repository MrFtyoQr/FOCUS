import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? params}) => _dio.get(path, queryParameters: params);
  Future<Response> post(String path, {dynamic data})                 => _dio.post(path, data: data);
  Future<Response> patch(String path, {dynamic data})                => _dio.patch(path, data: data);
  Future<Response> delete(String path)                               => _dio.delete(path);
}
