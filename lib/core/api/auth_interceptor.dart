import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    const publicPaths = [
      ApiEndpoints.login,
      ApiEndpoints.refresh,
      ApiEndpoints.acceptInvite,
    ];
    if (publicPaths.any((p) => options.path.contains(p))) {
      return handler.next(options);
    }

    final token = await SecureStorage.instance.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      final pending = _PendingRequest(err.requestOptions);
      _pendingRequests.add(pending);
      final response = await pending.future;
      return handler.resolve(response);
    }

    _isRefreshing = true;

    try {
      final refreshToken = await SecureStorage.instance.getRefreshToken();
      if (refreshToken == null) {
        await _forceLogout();
        return handler.next(err);
      }

      final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
      final response = await refreshDio.post(
        ApiEndpoints.refresh,
        data: {'refresh': refreshToken},
      );

      final newAccess  = response.data['access']  as String;
      final newRefresh = response.data['refresh'] as String;

      await SecureStorage.instance.saveTokens(
        access: newAccess, refresh: newRefresh,
      );

      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _dio.fetch(err.requestOptions);

      for (final pending in _pendingRequests) {
        pending.resolve(retryResponse);
      }
      _pendingRequests.clear();

      handler.resolve(retryResponse);
    } catch (_) {
      await _forceLogout();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _forceLogout() async {
    await SecureStorage.instance.clearAll();
  }
}

class _PendingRequest {
  final RequestOptions options;
  late final void Function(Response) resolve;
  late final Future<Response> future;

  _PendingRequest(this.options) {
    final completer = Completer<Response>();
    future  = completer.future;
    resolve = completer.complete;
  }
}
