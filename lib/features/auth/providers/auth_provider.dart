import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user.dart';

// ── Estado de sesión ──────────────────────────────────────────────────────────

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String?   error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user:   user   ?? this.user,
        error:  error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo)
      : super(const AuthState(status: AuthStatus.loading)) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasSession = await SecureStorage.instance.hasSession();
    if (!hasSession) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repo.getMe();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await SecureStorage.instance.clearAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _repo.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['detail'] ?? 'Error al iniciar sesión')
          : (e.message ?? 'Error al iniciar sesión');
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: msg.toString(),
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _repo.register(
        email: email,
        firstName: firstName,
        lastName: lastName,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      final detail = e.response?.data;
      String msg = 'Error al registrarse';
      if (detail is Map && detail['detail'] != null) {
        msg = detail['detail'].toString();
      } else if (e.message != null) {
        msg = e.message!;
      }
      state = AuthState(status: AuthStatus.unauthenticated, error: msg);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() => state = state.copyWith(error: null);
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider((_) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
