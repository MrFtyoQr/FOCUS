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
import '../../features/profile/screens/security_screen.dart';
import '../storage/local_prefs.dart';
import '../widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final isLoading       = authState.status == AuthStatus.loading;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final path            = state.matchedLocation;

      if (isLoading) return '/loading';

      // Deep link de invitación — siempre permitir
      if (path.startsWith('/invite/')) return null;

      if (!isAuthenticated) {
        final allowed = ['/login', '/register'];
        if (allowed.contains(path)) return null;
        return '/login';
      }

      // Autenticado — revisar onboarding
      final onboardingDone = await LocalPrefs.instance.isOnboardingCompleted();
      if (!onboardingDone && path != '/onboarding') {
        return '/onboarding';
      }

      // Redirigir de login/register al home si ya autenticado
      if (path == '/login' || path == '/register') return '/';

      return null;
    },
    routes: [
      // Loading splash
      GoRoute(
        path: '/loading',
        builder: (_, __) => const _LoadingScreen(),
      ),

      // Auth
      GoRoute(path: '/login',      builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',   builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/biometric',  builder: (_, __) => const BiometricScreen()),

      // Deep link invitación
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
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/capture',
            builder: (_, __) => const CaptureScreen(),
          ),
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
                  activityId:
                      int.parse(state.pathParameters['activityId']!),
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
