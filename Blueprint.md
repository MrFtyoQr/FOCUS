# Productivity App — Guía de Implementación Flutter

> **Stack:** Flutter · Riverpod · GoRouter · Dio · flutter_secure_storage · local_auth  
> **Targets:** iOS + Android  
> **Versión:** 1.0 · Tree Tech Solutions · 2026

---

## Índice

1. [pubspec.yaml — dependencias](#1-pubspecyaml--dependencias)
2. [Variables de entorno](#2-variables-de-entorno)
3. [Design system — colores y tipografía](#3-design-system--colores-y-tipografía)
4. [Almacenamiento seguro](#4-almacenamiento-seguro)
5. [API Client y interceptor JWT](#5-api-client-y-interceptor-jwt)
6. [Modelos compartidos](#6-modelos-compartidos)
7. [Autenticación — repositorio y provider](#7-autenticación--repositorio-y-provider)
8. [Biometría y PIN](#8-biometría-y-pin)
9. [GoRouter — navegación y deep links](#9-gorouter--navegación-y-deep-links)
10. [main.dart](#10-maindart)
11. [Feature: Dashboard](#11-feature-dashboard)
12. [Feature: Capture](#12-feature-capture)
13. [Feature: Projects](#13-feature-projects)
14. [Feature: Team y Asignación](#14-feature-team-y-asignación)
15. [Feature: Stats](#15-feature-stats)
16. [Feature: Profile](#16-feature-profile)
17. [Widgets globales](#17-widgets-globales)
18. [Checklist de arranque](#18-checklist-de-arranque)

---

## 1. pubspec.yaml — dependencias

```yaml
name: productivity_app
description: Productivity App — Tree Tech Solutions

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # HTTP
  dio: ^5.4.0

  # Estado
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Navegación
  go_router: ^13.2.0

  # Almacenamiento seguro (JWT)
  flutter_secure_storage: ^9.0.0

  # Preferencias ligeras (flags)
  shared_preferences: ^2.2.0

  # Biometría
  local_auth: ^2.2.0

  # Variables de entorno
  flutter_dotenv: ^5.1.0

  # Utilidades
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0

flutter:
  uses-material-design: true
  assets:
    - .env
    - assets/images/
    - assets/icons/
```

---

## 2. Variables de entorno

### 2.1 `.env`

```
API_BASE_URL=https://tu-dominio.com/api
```

> Agregar `.env` al `pubspec.yaml` en `flutter.assets` (ya incluido arriba) y al `.gitignore`.

### 2.2 `.env.example`

```
API_BASE_URL=
```

### 2.3 Acceso en código

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
```

---

## 3. Design system — colores y tipografía

### 3.1 `lib/core/theme/app_colors.dart`

```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Fondos
  static const background   = Color(0xFF141418);
  static const surface      = Color(0xFF1E1E28);
  static const surfaceBorder = Color(0xFF2E2E3A);

  // Texto
  static const textPrimary   = Color(0xFFE8E6E0);
  static const textSecondary = Color(0xFF888780);
  static const textTertiary  = Color(0xFF5F5E5A);

  // Acentos
  static const purple        = Color(0xFF7F77DD);
  static const purpleLight   = Color(0xFFAFA9EC);
  static const purpleDark    = Color(0xFF3C3489);

  static const teal          = Color(0xFF1D9E75);
  static const tealDark      = Color(0xFF0F6E56);

  static const amber         = Color(0xFFEF9F27);
  static const amberDark     = Color(0xFF854F0B);

  static const blue          = Color(0xFF378ADD);
  static const blueDark      = Color(0xFF185FA5);

  static const red           = Color(0xFFE24B4A);
  static const green         = Color(0xFF1D9E75);

  // Estados de actividad
  static Color statusColor(String status) {
    switch (status) {
      case 'hoy':        return teal;
      case 'manana':     return amber;
      case 'programado': return blue;
      case 'pendientes': return red;
      case 'completada': return green;
      default:           return textSecondary; // bandeja
    }
  }
}
```

### 3.2 `lib/core/theme/app_text_styles.dart`

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const heading1 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static const heading2 = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const heading3 = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );
  static const bodySecondary = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );
  static const caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary, letterSpacing: 0.04,
  );
  static const label = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: AppColors.textTertiary, letterSpacing: 0.06,
  );
}
```

### 3.3 `lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.purple,
      surface: AppColors.surface,
      error: AppColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleTextStyle: AppTextStyles.heading2,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.surfaceBorder, width: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.purple,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: AppColors.surfaceBorder,
    textTheme: const TextTheme(
      headlineLarge: AppTextStyles.heading1,
      headlineMedium: AppTextStyles.heading2,
      titleMedium: AppTextStyles.heading3,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.bodySecondary,
      labelSmall: AppTextStyles.caption,
    ),
  );
}
```

---

## 4. Almacenamiento seguro

### 4.1 `lib/core/storage/secure_storage.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();
  static const SecureStorage instance = SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessTokenKey  = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _pinKey          = 'user_pin';

  // ── JWT ──
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _accessTokenKey,  value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  Future<String?> getAccessToken()  async => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() async => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // ── PIN ──
  Future<void> savePin(String pin) async =>
      _storage.write(key: _pinKey, value: pin);

  Future<String?> getPin() async => _storage.read(key: _pinKey);

  Future<bool> hasPin() async => (await getPin()) != null;

  Future<void> clearPin() async => _storage.delete(key: _pinKey);

  // ── Sesión completa ──
  Future<bool> hasSession() async => (await getAccessToken()) != null;

  Future<void> clearAll() async => _storage.deleteAll();
}
```

### 4.2 `lib/core/storage/local_prefs.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  LocalPrefs._();
  static const LocalPrefs instance = LocalPrefs._();

  static const _onboardingKey    = 'onboarding_completed';
  static const _biometricEnabled = 'biometric_enabled';

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  Future<bool> isOnboardingCompleted() async =>
      (await _prefs).getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingCompleted() async =>
      (await _prefs).setBool(_onboardingKey, true);

  Future<bool> isBiometricEnabled() async =>
      (await _prefs).getBool(_biometricEnabled) ?? false;

  Future<void> setBiometricEnabled(bool value) async =>
      (await _prefs).setBool(_biometricEnabled, value);
}
```

---

## 5. API Client y interceptor JWT

> Este es el archivo más crítico del proyecto. El interceptor maneja el refresh silencioso del token — si no se implementa bien, la app cierra sesión cada hora.

### 5.1 `lib/core/api/api_endpoints.dart`

```dart
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const login              = '/auth/login/';
  static const refresh            = '/auth/refresh/';
  static const logout             = '/auth/logout/';
  static const me                 = '/auth/me/';
  static const inviteSend         = '/auth/invitations/send/';
  static const inviteAccept       = '/auth/invitations/accept/';
  static String inviteValidate(String token) => '/auth/invitations/$token/';
  static String inviteRegenerate(int id) => '/auth/invitations/$id/regenerate/';

  // Users
  static const users              = '/users/';
  static const inviteUser         = '/users/invite/';
  static String userDetail(int id) => '/users/$id/';

  // Areas
  static const areas              = '/areas/';
  static String areaDetail(int id) => '/areas/$id/';
  static String areaMembers(int id) => '/areas/$id/members/';

  // Activities
  static const activities         = '/activities/';
  static String activityDetail(int id) => '/activities/$id/';
  static String activityMove(int id) => '/activities/$id/move/';
  static String activityComplete(int id) => '/activities/$id/complete/';
  static String activityAssign(int id) => '/activities/$id/assign/';
  static String activityLog(int id) => '/activities/$id/log/';
  static String attachments(int id) => '/activities/$id/attachments/';
  static String attachmentDelete(int actId, int attId) =>
      '/activities/$actId/attachments/$attId/';

  // Projects
  static const projects           = '/projects/';
  static String projectDetail(int id) => '/projects/$id/';

  // Stats
  static const statsMe            = '/stats/me/';
  static const statsArea          = '/stats/area/';
  static String statsAreaDetail(int id) => '/stats/area/$id/';
}
```

### 5.2 `lib/core/api/auth_interceptor.dart`

```dart
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
    // Endpoints públicos — no requieren token
    final publicPaths = [
      ApiEndpoints.login,
      ApiEndpoints.refresh,
      ApiEndpoints.inviteAccept,
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

    // Si ya estamos refrescando, encolar la petición
    if (_isRefreshing) {
      final completer = _PendingRequest(err.requestOptions);
      _pendingRequests.add(completer);
      final response = await completer.future;
      return handler.resolve(response);
    }

    _isRefreshing = true;

    try {
      final refreshToken = await SecureStorage.instance.getRefreshToken();
      if (refreshToken == null) {
        await _forceLogout();
        return handler.next(err);
      }

      // Llamar al endpoint de refresh directamente (sin interceptor)
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

      // Reintentar petición original
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _dio.fetch(err.requestOptions);

      // Resolver peticiones pendientes
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
    // El router detecta el cambio en el provider de auth y redirige al login
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
```

### 5.3 `lib/core/api/api_client.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? '',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  Dio get dio => _dio;

  // ── Helpers ──
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
```

---

## 6. Modelos compartidos

### 6.1 `lib/shared/enums/activity_status.dart`

```dart
enum ActivityStatus {
  bandeja,
  hoy,
  manana,
  programado,
  pendientes,
  completada;

  String get label {
    switch (this) {
      case bandeja:    return 'Bandeja';
      case hoy:        return 'Hoy';
      case manana:     return 'Mañana';
      case programado: return 'Programado';
      case pendientes: return 'Pendientes';
      case completada: return 'Completada';
    }
  }

  static ActivityStatus fromString(String value) =>
      ActivityStatus.values.firstWhere((e) => e.name == value);
}
```

### 6.2 `lib/shared/enums/user_role.dart`

```dart
enum UserRole {
  superAdmin,
  adminArea,
  trabajador;

  String get label {
    switch (this) {
      case superAdmin: return 'Super Admin';
      case adminArea:  return 'Admin de Área';
      case trabajador: return 'Trabajador';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'super_admin': return UserRole.superAdmin;
      case 'admin_area':  return UserRole.adminArea;
      default:            return UserRole.trabajador;
    }
  }
}
```

### 6.3 `lib/shared/models/user.dart`

```dart
import '../enums/user_role.dart';

class UserModel {
  final int    id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final int?   areaId;
  final String? areaName;
  final bool   onboardingCompleted;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.areaId,
    this.areaName,
    this.onboardingCompleted = false,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdminArea  => role == UserRole.adminArea;
  bool get isTrabajador => role == UserRole.trabajador;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:                  json['id'] as int,
    email:               json['email'] as String,
    firstName:           json['first_name'] as String,
    lastName:            json['last_name'] as String,
    role:                UserRole.fromString(json['role'] as String),
    areaId:              json['area'] as int?,
    areaName:            json['area_name'] as String?,
    onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name':  lastName,
  };
}
```

### 6.4 `lib/shared/models/activity.dart`

```dart
import '../enums/activity_status.dart';

class ActivityModel {
  final int            id;
  final String         title;
  final String         description;
  final ActivityStatus status;
  final int            ownerId;
  final String         ownerName;
  final int?           assignedToId;
  final String?        assignedToName;
  final int?           assignedById;
  final String?        assignedByName;
  final int?           projectId;
  final String?        projectName;
  final int?           areaId;
  final String?        areaName;
  final DateTime?      targetDate;
  final DateTime?      completedAt;
  final DateTime       createdAt;
  final DateTime       updatedAt;

  const ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.ownerId,
    required this.ownerName,
    this.assignedToId,
    this.assignedToName,
    this.assignedById,
    this.assignedByName,
    this.projectId,
    this.projectName,
    this.areaId,
    this.areaName,
    this.targetDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAssigned => assignedById != null;
  bool get isCompleted => status == ActivityStatus.completada;

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
    id:             json['id'] as int,
    title:          json['title'] as String,
    description:    json['description'] as String? ?? '',
    status:         ActivityStatus.fromString(json['status'] as String),
    ownerId:        json['owner'] as int,
    ownerName:      json['owner_name'] as String,
    assignedToId:   json['assigned_to'] as int?,
    assignedToName: json['assigned_to_name'] as String?,
    assignedById:   json['assigned_by'] as int?,
    assignedByName: json['assigned_by_name'] as String?,
    projectId:      json['project'] as int?,
    projectName:    json['project_name'] as String?,
    areaId:         json['area'] as int?,
    areaName:       json['area_name'] as String?,
    targetDate:     json['target_date'] != null
        ? DateTime.parse(json['target_date'] as String) : null,
    completedAt:    json['completed_at'] != null
        ? DateTime.parse(json['completed_at'] as String) : null,
    createdAt:      DateTime.parse(json['created_at'] as String),
    updatedAt:      DateTime.parse(json['updated_at'] as String),
  );
}
```

### 6.5 `lib/shared/models/project.dart`

```dart
class ProjectModel {
  final int    id;
  final String name;
  final String description;
  final String color;
  final int    ownerId;
  final String ownerName;
  final int?   areaId;
  final String? areaName;
  final int    totalActivities;
  final int    completedActivities;
  final DateTime createdAt;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.ownerId,
    required this.ownerName,
    this.areaId,
    this.areaName,
    required this.totalActivities,
    required this.completedActivities,
    required this.createdAt,
  });

  double get progress => totalActivities == 0
      ? 0 : completedActivities / totalActivities;

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id:                   json['id'] as int,
    name:                 json['name'] as String,
    description:          json['description'] as String? ?? '',
    color:                json['color'] as String? ?? '#7F77DD',
    ownerId:              json['owner'] as int,
    ownerName:            json['owner_name'] as String,
    areaId:               json['area'] as int?,
    areaName:             json['area_name'] as String?,
    totalActivities:      json['total_activities'] as int? ?? 0,
    completedActivities:  json['completed_activities'] as int? ?? 0,
    createdAt:            DateTime.parse(json['created_at'] as String),
  );
}
```

---

## 7. Autenticación — repositorio y provider

### 7.1 `lib/features/auth/data/auth_repository.dart`

```dart
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../shared/models/user.dart';

class AuthRepository {
  final _api = ApiClient.instance;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(ApiEndpoints.login, data: {
      'email': email, 'password': password,
    });
    await SecureStorage.instance.saveTokens(
      access:  response.data['access']  as String,
      refresh: response.data['refresh'] as String,
    );
    return getMe();
  }

  Future<UserModel> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    // Registro libre — el backend crea el usuario y devuelve JWT
    final response = await _api.post('/auth/register/', data: {
      'email': email, 'first_name': firstName,
      'last_name': lastName, 'password': password,
    });
    await SecureStorage.instance.saveTokens(
      access:  response.data['access']  as String,
      refresh: response.data['refresh'] as String,
    );
    return getMe();
  }

  Future<UserModel> acceptInvitation({
    required String token,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final response = await _api.post(ApiEndpoints.inviteAccept, data: {
      'token': token, 'first_name': firstName,
      'last_name': lastName, 'password': password,
    });
    await SecureStorage.instance.saveTokens(
      access:  response.data['access']  as String,
      refresh: response.data['refresh'] as String,
    );
    return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
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
      // Si falla el logout en el backend, igual limpiamos local
    } finally {
      await SecureStorage.instance.clearAll();
    }
  }

  Future<Map<String, dynamic>> validateInviteToken(String token) async {
    final response = await _api.get(ApiEndpoints.inviteValidate(token));
    return response.data as Map<String, dynamic>;
  }
}
```

### 7.2 `lib/features/auth/providers/auth_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user.dart';

// Estado de sesión
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

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState(status: AuthStatus.loading)) {
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

  Future<void> login({required String email, required String password}) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _repo.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? 'Error al iniciar sesión';
      state = AuthState(status: AuthStatus.unauthenticated, error: msg.toString());
    }
  }

  Future<void> register({
    required String email, required String firstName,
    required String lastName, required String password,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _repo.register(
        email: email, firstName: firstName,
        lastName: lastName, password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      final msg = e.response?.data ?? 'Error al registrarse';
      state = AuthState(status: AuthStatus.unauthenticated, error: msg.toString());
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() => state = state.copyWith(error: null);
}

// Providers
final authRepositoryProvider = Provider((_) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// Shortcut para el usuario actual
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
```

---

## 8. Biometría y PIN

### 8.1 `lib/core/security/biometric_service.dart`

```dart
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../storage/secure_storage.dart';
import '../storage/local_prefs.dart';

enum BiometricResult { success, failure, notAvailable, lockedOut }

class BiometricService {
  BiometricService._();
  static const BiometricService instance = BiometricService._();

  final _auth = LocalAuthentication();

  // ── Disponibilidad ──
  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  // ── Autenticación biométrica ──
  Future<BiometricResult> authenticate() async {
    try {
      final available = await isAvailable();
      if (!available) return BiometricResult.notAvailable;

      final authenticated = await _auth.authenticate(
        localizedReason: 'Confirma tu identidad para acceder',
        options: const AuthenticationOptions(
          biometricOnly: false,   // permite PIN del SO como fallback
          stickyAuth: true,
        ),
      );
      return authenticated ? BiometricResult.success : BiometricResult.failure;
    } on PlatformException catch (e) {
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return BiometricResult.lockedOut;
      }
      return BiometricResult.failure;
    }
  }

  // ── PIN propio de la app (fallback cuando el SO no tiene biometría) ──
  Future<bool> validatePin(String inputPin) async {
    final savedPin = await SecureStorage.instance.getPin();
    return savedPin != null && savedPin == inputPin;
  }

  Future<void> savePin(String pin) async {
    await SecureStorage.instance.savePin(pin);
    await LocalPrefs.instance.setBiometricEnabled(true);
  }

  // ── Flujo de desbloqueo completo ──
  // Retorna true si el usuario puede entrar, false si debe hacer logout
  Future<bool> unlock({int maxAttempts = 3}) async {
    final biometricEnabled = await LocalPrefs.instance.isBiometricEnabled();
    final biometricAvailable = await isAvailable();

    if (biometricAvailable && biometricEnabled) {
      final result = await authenticate();
      if (result == BiometricResult.success) return true;
      if (result == BiometricResult.lockedOut) return false;
    }

    // Fallback a PIN de la app — se maneja en la UI con contador
    return false;
  }
}
```

### 8.2 `lib/features/auth/screens/biometric_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});

  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen> {
  final _pinController = TextEditingController();
  int _failedAttempts = 0;
  static const _maxAttempts = 3;
  bool _showPin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    final result = await BiometricService.instance.authenticate();
    if (!mounted) return;

    if (result == BiometricResult.success) {
      _onSuccess();
    } else if (result == BiometricResult.notAvailable) {
      setState(() => _showPin = true);
    } else if (result == BiometricResult.lockedOut) {
      _onMaxAttempts();
    }
  }

  Future<void> _validatePin() async {
    final valid = await BiometricService.instance.validatePin(_pinController.text);
    if (!mounted) return;

    if (valid) {
      _onSuccess();
    } else {
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        _onMaxAttempts();
      } else {
        setState(() {
          _error = 'PIN incorrecto. Intentos restantes: ${_maxAttempts - _failedAttempts}';
          _pinController.clear();
        });
      }
    }
  }

  void _onSuccess() {
    // El router redirige al tablero
    context.go('/');
  }

  void _onMaxAttempts() {
    ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: AppColors.purple, size: 56),
              const SizedBox(height: 24),
              Text('Verifica tu identidad', style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              Text(
                _showPin
                    ? 'Ingresa tu PIN para continuar'
                    : 'Usa biometría para desbloquear',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              if (_showPin) ...[
                const SizedBox(height: 32),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'PIN',
                    counterText: '',
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _validatePin,
                  child: const Text('Confirmar'),
                ),
              ] else ...[
                const SizedBox(height: 32),
                TextButton(
                  onPressed: _tryBiometric,
                  child: Text('Reintentar', style: TextStyle(color: AppColors.purple)),
                ),
                TextButton(
                  onPressed: () => setState(() => _showPin = true),
                  child: Text('Usar PIN', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
```

---

## 9. GoRouter — navegación y deep links

### 9.1 `lib/core/router/app_router.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/biometric_screen.dart';
import '../../features/auth/screens/invite_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/dashboard/screens/activity_detail_screen.dart';
import '../../features/capture/screens/capture_screen.dart';
import '../../features/projects/screens/projects_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/stats/screens/stats_screen.dart';
import '../../features/team/screens/team_screen.dart';
import '../../features/team/screens/assign_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../storage/local_prefs.dart';
import '../storage/secure_storage.dart';
import '../widgets/main_shell.dart';  // Bottom nav wrapper

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final isLoading        = authState.status == AuthStatus.loading;
      final isAuthenticated  = authState.status == AuthStatus.authenticated;
      final isInvitePath     = state.matchedLocation.startsWith('/invite/');

      if (isLoading) return '/loading';

      // Deep link de invitación — siempre permitir
      if (isInvitePath) return null;

      if (!isAuthenticated) {
        if (state.matchedLocation == '/login' ||
            state.matchedLocation == '/register') return null;
        return '/login';
      }

      // Usuario autenticado — revisar onboarding
      final onboardingDone = await LocalPrefs.instance.isOnboardingCompleted();
      if (!onboardingDone && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      // Loading
      GoRoute(path: '/loading', builder: (_, __) => const _LoadingScreen()),

      // Auth
      GoRoute(path: '/login',      builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',   builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/biometric',  builder: (_, __) => const BiometricScreen()),

      // Deep link invitación
      GoRoute(
        path: '/invite/:token',
        builder: (_, state) => InviteScreen(
          token: state.pathParameters['token']!,
        ),
      ),

      // App principal con bottom nav
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const DashboardScreen(),
            routes: [
              GoRoute(
                path: 'activity/:id',
                builder: (_, state) => ActivityDetailScreen(
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(path: '/capture',  builder: (_, __) => const CaptureScreen()),
          GoRoute(
            path: '/projects',
            builder: (_, __) => const ProjectsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => ProjectDetailScreen(
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(path: '/stats',   builder: (_, __) => const StatsScreen()),
          GoRoute(
            path: '/team',
            builder: (_, __) => const TeamScreen(),
            routes: [
              GoRoute(
                path: 'assign/:activityId',
                builder: (_, state) => AssignScreen(
                  activityId: int.parse(state.pathParameters['activityId']!),
                ),
              ),
            ],
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}
```

### 9.2 `lib/core/widgets/main_shell.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    (path: '/',          label: 'Tablero',      icon: Icons.grid_view_rounded),
    (path: '/capture',   label: 'Capturar',     icon: Icons.add_circle_outline_rounded),
    (path: '/projects',  label: 'Proyectos',    icon: Icons.folder_outlined),
    (path: '/stats',     label: 'Productividad',icon: Icons.trending_up_rounded),
    (path: '/team',      label: 'Equipo',       icon: Icons.group_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => t.path == location).clamp(0, 4);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => context.go(_tabs[i].path),
          items: _tabs.map((t) => BottomNavigationBarItem(
            icon: Icon(t.icon),
            label: t.label,
          )).toList(),
        ),
      ),
    );
  }
}
```

---

## 10. main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: '.env');

  // Inicializar cliente HTTP
  ApiClient.instance.initialize();

  runApp(
    const ProviderScope(
      child: ProductivityApp(),
    ),
  );
}

class ProductivityApp extends ConsumerWidget {
  const ProductivityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Productivity App',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

## 11. Feature: Dashboard

### 11.1 `lib/features/dashboard/data/activity_repository.dart`

```dart
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../shared/models/activity.dart';

class ActivityRepository {
  final _api = ApiClient.instance;

  Future<List<ActivityModel>> getActivities({String? status, int? projectId}) async {
    final params = <String, dynamic>{};
    if (status != null)    params['status'] = status;
    if (projectId != null) params['project_id'] = projectId;

    final response = await _api.get(ApiEndpoints.activities, params: params);
    final results = response.data['results'] as List? ?? response.data as List;
    return results.map((e) => ActivityModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ActivityModel> getActivity(int id) async {
    final response = await _api.get(ApiEndpoints.activityDetail(id));
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityModel> createActivity({
    required String title,
    String? description,
    required String status,
    int? projectId,
    DateTime? targetDate,
  }) async {
    final response = await _api.post(ApiEndpoints.activities, data: {
      'title': title,
      if (description != null) 'description': description,
      'status': status,
      if (projectId != null) 'project': projectId,
      if (targetDate != null) 'target_date': targetDate.toIso8601String().split('T')[0],
    });
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityModel> moveActivity(int id, String status) async {
    final response = await _api.patch(ApiEndpoints.activityMove(id), data: {'status': status});
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityModel> completeActivity(int id) async {
    final response = await _api.patch(ApiEndpoints.activityComplete(id));
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityModel> assignActivity(int id, int assignedToId) async {
    final response = await _api.patch(
      ApiEndpoints.activityAssign(id),
      data: {'assigned_to': assignedToId},
    );
    return ActivityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteActivity(int id) async {
    await _api.delete(ApiEndpoints.activityDetail(id));
  }
}
```

### 11.2 `lib/features/dashboard/providers/dashboard_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/activity_repository.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/enums/activity_status.dart';

final activityRepositoryProvider = Provider((_) => ActivityRepository());

final activitiesProvider = FutureProvider.family<List<ActivityModel>, String?>(
  (ref, status) async {
    final repo = ref.read(activityRepositoryProvider);
    return repo.getActivities(status: status);
  },
);

// Activididades agrupadas por columna para el tablero
final dashboardProvider = FutureProvider<Map<ActivityStatus, List<ActivityModel>>>(
  (ref) async {
    final repo = ref.read(activityRepositoryProvider);
    final all  = await repo.getActivities();

    return {
      for (final status in ActivityStatus.values.where((s) => s != ActivityStatus.completada))
        status: all.where((a) => a.status == status).toList(),
    };
  },
);
```

---

## 12. Feature: Capture

### 12.1 `lib/features/capture/providers/capture_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/data/activity_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../shared/models/activity.dart';

class CaptureNotifier extends StateNotifier<AsyncValue<void>> {
  final ActivityRepository _repo;
  final Ref _ref;

  CaptureNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<ActivityModel?> capture({
    required String title,
    String? description,
    required String status,
    int? projectId,
    DateTime? targetDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final activity = await _repo.createActivity(
        title: title, description: description,
        status: status, projectId: projectId, targetDate: targetDate,
      );
      // Invalidar el tablero para que recargue
      _ref.invalidate(dashboardProvider);
      state = const AsyncValue.data(null);
      return activity;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final captureProvider = StateNotifierProvider<CaptureNotifier, AsyncValue<void>>(
  (ref) => CaptureNotifier(ref.read(activityRepositoryProvider), ref),
);
```

---

## 13. Feature: Projects

### 13.1 `lib/features/projects/data/project_repository.dart`

```dart
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../shared/models/project.dart';
import '../../../shared/models/activity.dart';

class ProjectRepository {
  final _api = ApiClient.instance;

  Future<List<ProjectModel>> getProjects() async {
    final response = await _api.get(ApiEndpoints.projects);
    final results = response.data['results'] as List? ?? response.data as List;
    return results.map((e) => ProjectModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProjectModel> getProject(int id) async {
    final response = await _api.get(ApiEndpoints.projectDetail(id));
    return ProjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProjectModel> createProject({
    required String name,
    String? description,
    String color = '#7F77DD',
  }) async {
    final response = await _api.post(ApiEndpoints.projects, data: {
      'name': name,
      if (description != null) 'description': description,
      'color': color,
    });
    return ProjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteProject(int id) async {
    await _api.delete(ApiEndpoints.projectDetail(id));
  }
}
```

### 13.2 `lib/features/projects/providers/projects_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/project_repository.dart';
import '../../../shared/models/project.dart';

final projectRepositoryProvider = Provider((_) => ProjectRepository());

final projectsProvider = FutureProvider<List<ProjectModel>>((ref) {
  return ref.read(projectRepositoryProvider).getProjects();
});

final projectDetailProvider = FutureProvider.family<ProjectModel, int>((ref, id) {
  return ref.read(projectRepositoryProvider).getProject(id);
});
```

---

## 14. Feature: Team y Asignación

### 14.1 `lib/features/team/data/team_repository.dart`

```dart
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../shared/models/user.dart';

class TeamRepository {
  final _api = ApiClient.instance;

  Future<List<UserModel>> getTeamMembers() async {
    final response = await _api.get(ApiEndpoints.users);
    final results = response.data['results'] as List? ?? response.data as List;
    return results.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserModel>> getAreaMembers(int areaId) async {
    final response = await _api.get(ApiEndpoints.areaMembers(areaId));
    return (response.data as List)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> generateInviteLink({
    required String email,
    required String role,
    int? areaId,
  }) async {
    final response = await _api.post(ApiEndpoints.inviteSend, data: {
      'email': email,
      'role':  role,
      if (areaId != null) 'area': areaId,
    });
    return response.data['link'] as String;
  }
}
```

### 14.2 `lib/features/team/providers/team_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/team_repository.dart';
import '../../../shared/models/user.dart';

final teamRepositoryProvider = Provider((_) => TeamRepository());

final teamMembersProvider = FutureProvider<List<UserModel>>((ref) {
  return ref.read(teamRepositoryProvider).getTeamMembers();
});

final areaMembersProvider = FutureProvider.family<List<UserModel>, int>((ref, areaId) {
  return ref.read(teamRepositoryProvider).getAreaMembers(areaId);
});
```

---

## 15. Feature: Stats

### 15.1 `lib/features/stats/data/stats_repository.dart`

```dart
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class StatsRepository {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> getMyStats() async {
    final response = await _api.get(ApiEndpoints.statsMe);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAreaStats() async {
    final response = await _api.get(ApiEndpoints.statsArea);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAreaDetailStats(int areaId) async {
    final response = await _api.get(ApiEndpoints.statsAreaDetail(areaId));
    return response.data as Map<String, dynamic>;
  }
}
```

### 15.2 `lib/features/stats/providers/stats_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stats_repository.dart';

final statsRepositoryProvider = Provider((_) => StatsRepository());

final myStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(statsRepositoryProvider).getMyStats();
});

final areaStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(statsRepositoryProvider).getAreaStats();
});
```

---

## 16. Feature: Profile

### 16.1 `lib/features/profile/providers/profile_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/auth_repository.dart';

class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  final Ref _ref;

  ProfileNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.getMe(); // Re-fetch actualizado
      _ref.invalidate(authProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<void>>(
  (ref) => ProfileNotifier(ref.read(authRepositoryProvider), ref),
);
```

---

## 17. Widgets globales

### 17.1 `lib/core/widgets/activity_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../shared/models/activity.dart';
import '../../shared/enums/activity_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activity.isCompleted
                ? AppColors.teal.withOpacity(0.3)
                : AppColors.surfaceBorder,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    activity.title,
                    style: AppTextStyles.heading3.copyWith(
                      decoration: activity.isCompleted
                          ? TextDecoration.lineThrough : null,
                      color: activity.isCompleted
                          ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: activity.status),
              ],
            ),
            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(activity.description,
                  style: AppTextStyles.bodySecondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (activity.isAssigned) ...[
                  _AssignedBadge(assignedBy: activity.assignedByName ?? ''),
                  const SizedBox(width: 6),
                ],
                if (activity.projectName != null)
                  _ProjectChip(name: activity.projectName!),
                const Spacer(),
                if (activity.targetDate != null)
                  Text(
                    _formatDate(activity.targetDate!),
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final ActivityStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

class _AssignedBadge extends StatelessWidget {
  final String assignedBy;
  const _AssignedBadge({required this.assignedBy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('Asignada · $assignedBy',
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w500,
              color: AppColors.purpleLight)),
    );
  }
}

class _ProjectChip extends StatelessWidget {
  final String name;
  const _ProjectChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(name,
          style: const TextStyle(
              fontSize: 10, color: AppColors.teal, fontWeight: FontWeight.w500)),
    );
  }
}
```

### 17.2 `lib/core/widgets/empty_state.dart`

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: 6),
          Text(subtitle,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
```

---

## 18. Checklist de arranque

### Configuración inicial

```bash
# Crear proyecto Flutter
flutter create productivity_app --org mx.tts
cd productivity_app

# Instalar dependencias
flutter pub get

# Verificar que corre
flutter run
```

### Permisos nativos

**`android/app/src/main/AndroidManifest.xml`** — agregar dentro de `<manifest>`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

**`ios/Runner/Info.plist`** — agregar dentro de `<dict>`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>Usa Face ID para desbloquear la app</string>
```

### Orden de implementación recomendado

1. `pubspec.yaml` + `flutter pub get`
2. `.env` con la URL del backend
3. `app_colors.dart` + `app_theme.dart`
4. `secure_storage.dart` + `local_prefs.dart`
5. `api_client.dart` + `auth_interceptor.dart`
6. Modelos compartidos (`user.dart`, `activity.dart`, etc.)
7. `auth_provider.dart` + `auth_repository.dart`
8. `app_router.dart` + `main.dart` — verificar que navega
9. `biometric_service.dart` + `biometric_screen.dart`
10. Features en orden: `auth` → `dashboard` → `capture` → `projects` → `team` → `stats` → `profile`

---

*Productivity App · Tree Tech Solutions · 2026*