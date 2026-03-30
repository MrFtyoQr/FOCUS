import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pending = [];

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    const publicPaths = [ApiEndpoints.login, ApiEndpoints.refresh, ApiEndpoints.inviteAccept];
    if (publicPaths.any((p) => options.path.contains(p))) return handler.next(options);

    final token = await SecureStorage.instance.getAccessToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) return handler.next(err);

    if (_isRefreshing) {
      final req = _PendingRequest(err.requestOptions);
      _pending.add(req);
      return handler.resolve(await req.future);
    }

    _isRefreshing = true;
    try {
      final refreshToken = await SecureStorage.instance.getRefreshToken();
      if (refreshToken == null) { await _forceLogout(); return handler.next(err); }

      final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
      final res = await refreshDio.post(ApiEndpoints.refresh, data: {'refresh': refreshToken});

      final newAccess  = res.data['access']  as String;
      final newRefresh = res.data['refresh'] as String;
      await SecureStorage.instance.saveTokens(access: newAccess, refresh: newRefresh);

      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryRes = await _dio.fetch(err.requestOptions);
      for (final p in _pending) p.resolve(retryRes);
      _pending.clear();
      handler.resolve(retryRes);
    } catch (_) {
      await _forceLogout();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _forceLogout() async => SecureStorage.instance.clearAll();
}

class _PendingRequest {
  final RequestOptions options;
  late final void Function(Response) resolve;
  late final Future<Response> future;

  _PendingRequest(this.options) {
    final c = Completer<Response>();
    future  = c.future;
    resolve = c.complete;
  }
}
