import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_prefs.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'app.env');
  ApiClient.instance.initialize();

  final initialThemeMode = await LocalPrefs.instance.getThemeMode();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith((ref) => initialThemeMode),
      ],
      child: const HiperApp(),
    ),
  );
}

class HiperApp extends ConsumerStatefulWidget {
  const HiperApp({super.key});

  @override
  ConsumerState<HiperApp> createState() => _HiperAppState();
}

class _HiperAppState extends ConsumerState<HiperApp> {
  @override
  Widget build(BuildContext context) {
    final router    = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return SlidableAutoCloseBehavior(
      child: MaterialApp.router(
        title: 'HiperApp',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
