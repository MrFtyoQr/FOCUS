import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Variables de entorno (.env)
  await dotenv.load(fileName: '.env');

  // Inicializar cliente HTTP con el interceptor JWT
  ApiClient.instance.initialize();

  runApp(
    const ProviderScope(
      child: HiperApp(),
    ),
  );
}

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
