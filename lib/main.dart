import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'utils/app_theme.dart';
import 'data/api/api_client.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/unlock_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  // Cliente API (Bearer + X-Device-Fingerprint)
  ApiClient().init();

  await DatabaseService().initialize();

  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.programarNotificacionesDiarias();
  } catch (e) {
    debugPrint('Error al inicializar notificaciones: $e');
  }

  runApp(const HiperApp());
}

class HiperApp extends StatelessWidget {
  const HiperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HiperApp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

/// Decide si mostrar Login, Desbloqueo o Home según sesión y requiresUnlock.
/// Sin sesión (primera vez): Login/Registro, no se pide biometría.
/// Con sesión: se exige desbloqueo (PIN/huella) en cada arranque en frío y al volver del segundo plano.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  bool _checked = false;
  bool _hasSession = false;
  bool _requiresUnlock = false;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al salir de la app (background/inactive), exigir desbloqueo al volver.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_hasSession && _checked) {
        setState(() => _requiresUnlock = true);
      }
    }
  }

  Future<void> _checkAuth() async {
    final hasSession = await _authService.hasSession();
    // Con sesión, SIEMPRE exigir desbloqueo en este arranque (también si cerró la app y la reabrió).
    final requiresUnlock = hasSession;
    if (mounted) {
      setState(() {
        _hasSession = hasSession;
        _requiresUnlock = requiresUnlock;
        _checked = true;
      });
    }
  }

  void _onLoginSuccess() {
    setState(() {
      _hasSession = true;
      _requiresUnlock = true;
    });
  }

  void _onUnlocked() {
    setState(() => _requiresUnlock = false);
  }

  void _onLogout() async {
    await _authService.logout();
    if (mounted) {
      setState(() {
        _hasSession = false;
        _requiresUnlock = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_hasSession) {
      if (_showRegister) {
        return RegisterScreen(
          onBackToLogin: () => setState(() => _showRegister = false),
          onRegisterSuccess: () => setState(() => _showRegister = false),
        );
      }
      return LoginScreen(
        onLoginSuccess: _onLoginSuccess,
        onGoToRegister: () => setState(() => _showRegister = true),
      );
    }
    if (_requiresUnlock) {
      return UnlockScreen(onUnlocked: _onUnlocked, onLogout: _onLogout);
    }
    return MainNavigation(onLogout: _onLogout);
  }
}
