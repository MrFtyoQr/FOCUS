import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/startup_animation_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/biometric_screen.dart';
import '../../features/auth/screens/invite_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/dashboard/screens/activity_detail_screen.dart';
import '../../features/dashboard/screens/historial_screen.dart';
import '../../features/capture/screens/capture_screen.dart';
import '../../features/projects/screens/projects_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/stats/screens/stats_screen.dart';
import '../../features/team/screens/team_screen.dart';
import '../../features/team/screens/assign_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/security_screen.dart';
import '../storage/local_prefs.dart';
import '../widgets/main_shell.dart';

// ── Notifier que puente Riverpod → GoRouter refreshListenable ────────────────
// GoRouter recibe un Listenable; cuando el estado de auth cambia,
// solo re-evalúa el redirect actual sin reconstruir el árbol de widgets.
class _AuthRouterNotifier extends ChangeNotifier {
  AuthState _state;

  _AuthRouterNotifier(this._state);

  AuthState get authState => _state;

  void update(AuthState next) {
    // Solo notificar si el status cambia, para evitar rebuilds innecesarios.
    if (_state.status != next.status) {
      _state = next;
      notifyListeners();
    }
  }
}

final _authRouterNotifierProvider =
    ChangeNotifierProvider<_AuthRouterNotifier>((ref) {
  final notifier = _AuthRouterNotifier(
    const AuthState(status: AuthStatus.loading),
  );
  // ref.listen escucha sin reconstruir; delega al notifier del router.
  ref.listen<AuthState>(authProvider, (_, next) => notifier.update(next));
  return notifier;
});

// ── Router principal ──────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  // `read`: un solo GoRouter durante toda la vida de la app. Si se usara `watch`
  // sobre el ChangeNotifier, cada cambio de auth recrearía el router y volvería a
  // `initialLocation` (/splash), mostrando la animación otra vez al iniciar sesión.
  final notifier = ref.read(_authRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) async {
      final authStatus = notifier.authState.status;
      final path       = state.matchedLocation;

      // Animación de inicio: si la sesión aún se resuelve, quedarse en /splash
      if (authStatus == AuthStatus.loading) {
        if (path == '/splash') return null;
        return '/loading';
      }

      final isAuthenticated = authStatus == AuthStatus.authenticated;

      if (isAuthenticated && path == '/loading') {
        final onboardingDone = await LocalPrefs.instance.isOnboardingCompleted();
        return onboardingDone ? '/' : '/onboarding';
      }

      // Flujos de invitación — siempre permitir sin auth
      if (path.startsWith('/invite/') || path == '/join') return null;

      if (!isAuthenticated) {
        if (path == '/loading') return '/login';
        final allowed = {'/login', '/register', '/splash'};
        return allowed.contains(path) ? null : '/login';
      }

      // Dejar terminar la animación de inicio (también con sesión ya restaurada)
      if (path == '/splash') return null;

      // Autenticado — revisar onboarding
      final onboardingDone = await LocalPrefs.instance.isOnboardingCompleted();
      if (!onboardingDone && path != '/onboarding') return '/onboarding';

      // Ya autenticado → salir de login/register al home
      if (path == '/login' || path == '/register') return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const StartupAnimationScreen(),
      ),
      // Splash de carga (auth aún resolviéndose tras animación)
      GoRoute(
        path: '/loading',
        builder: (_, __) => const _LoadingScreen(),
      ),

      // Auth
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          entryFromSplash: state.extra == true,
        ),
      ),
      GoRoute(path: '/register',   builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/biometric',  builder: (_, __) => const BiometricScreen()),

      // Unirse con código (entrada manual — flujo principal)
      GoRoute(
        path: '/join',
        builder: (_, __) => const InviteScreen(token: ''),
      ),

      // Deep link de invitación (token pre-cargado desde URL)
      GoRoute(
        path: '/invite/:token',
        builder: (_, state) =>
            InviteScreen(token: state.pathParameters['token']!),
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
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/capture',
            builder: (_, __) => const CaptureScreen(),
          ),
          GoRoute(
            path: '/historial',
            builder: (_, __) => const HistorialScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (_, __) => const ProjectsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => ProjectDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/stats',
            builder: (_, __) => const StatsScreen(),
          ),
          GoRoute(
            path: '/team',
            builder: (_, __) => const TeamScreen(),
            routes: [
              GoRoute(
                path: 'assign/:activityId',
                builder: (_, state) => AssignScreen(
                  activityId: state.pathParameters['activityId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'security',
                builder: (_, __) => const SecurityScreen(),
              ),
            ],
          ),
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
