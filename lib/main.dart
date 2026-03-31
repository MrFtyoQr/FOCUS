import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/storage/local_prefs.dart';
import 'core/theme/app_theme.dart';
import 'core/mock/mock_repositories.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/projects/providers/projects_provider.dart';
import 'features/team/providers/team_provider.dart';
import 'features/stats/providers/stats_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'app.env');

  final useMock = dotenv.env['USE_MOCK'] == 'true';

  if (useMock) {
    // Siempre limpiar sesión al arrancar en mock para forzar el flujo de login.
    await SecureStorage.instance.clearAll();
    await LocalPrefs.instance.clearOnboarding();
  } else {
    ApiClient.instance.initialize();
  }

  runApp(
    ProviderScope(
      overrides: useMock ? _mockOverrides() : const [],
      child: const HiperApp(),
    ),
  );
}

List<Override> _mockOverrides() => [
  authRepositoryProvider    .overrideWith((_) => MockAuthRepository()),
  activityRepositoryProvider.overrideWith((_) => MockActivityRepository()),
  projectRepositoryProvider .overrideWith((_) => MockProjectRepository()),
  teamRepositoryProvider    .overrideWith((_) => MockTeamRepository()),
  statsRepositoryProvider   .overrideWith((_) => MockStatsRepository()),
];

class HiperApp extends ConsumerWidget {
  const HiperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'HiperApp',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
