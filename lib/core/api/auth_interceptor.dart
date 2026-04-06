import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      ApiEndpoints.verifyInvite,
      ApiEndpoints.acceptInvite,
    ];
    if (publicPaths.any((p) => options.path.contains(p))) {
      return handler.next(options);
    }

    final token = await SecureStorage.instance.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      debugPrint('[AUTH] Sin access token para ${options.method} ${options.path}');
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

    // Si ya hay un refresh en curso, encolar y esperar su resultado.
    if (_isRefreshing) {
      final pending = _PendingRequest(err.requestOptions);
      _pendingRequests.add(pending);
      try {
        final response = await pending.future;
        return handler.resolve(response);
      } catch (e) {
        // El refresh principal falló — rechazar esta request también.
        return handler.next(err);
      }
    }

    _isRefreshing = true;

    try {
      final refreshToken = await SecureStorage.instance.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('[AUTH] Sin refresh token — forzando logout');
        await _forceLogout();
        _rejectPending(err);
        return handler.next(err);
      }

      debugPrint('[AUTH] Token expirado, intentando refresh…');
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final response = await refreshDio.post(
        ApiEndpoints.refresh,
        data: {'refresh': refreshToken},
      );

      final newAccess  = response.data['access']  as String;
      final newRefresh = response.data['refresh'] as String;

      debugPrint('[AUTH] Refresh exitoso, reintentando ${err.requestOptions.method} ${err.requestOptions.path}');
      await SecureStorage.instance.saveTokens(
        access: newAccess, refresh: newRefresh,
      );

      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _dio.fetch(err.requestOptions);

      // Resolver todas las requests que estaban esperando.
      for (final pending in _pendingRequests) {
        pending.resolve(retryResponse);
      }
      _pendingRequests.clear();

      handler.resolve(retryResponse);
    } catch (e) {
      // Refresh falló (500, red, token expirado definitivamente).
      // CRÍTICO: rechazar todas las requests en cola para evitar deadlock.
      debugPrint('[AUTH] Refresh fallido ($e) — forzando logout');
      await _forceLogout();
      _rejectPending(err);
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Rechaza y limpia todas las requests pendientes para evitar deadlock.
  void _rejectPending(DioException originalErr) {
    for (final pending in _pendingRequests) {
      pending.reject(originalErr);
    }
    _pendingRequests.clear();
  }

  Future<void> _forceLogout() async {
    await SecureStorage.instance.clearAll();
  }
}

class _PendingRequest {
  final RequestOptions options;
  late final void Function(Response) resolve;
  late final void Function(DioException) reject;
  late final Future<Response> future;

  _PendingRequest(this.options) {
    final completer = Completer<Response>();
    future  = completer.future;
    resolve = completer.complete;
    reject  = (err) => completer.completeError(err);
  }
}
