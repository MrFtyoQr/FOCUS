import 'package:flutter/material.dart';
import 'utils/app_theme.dart';
import 'screens/main_navigation.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar base de datos
  await DatabaseService().initialize();

  runApp(const HiperApp());
}

class HiperApp extends StatelessWidget {
  const HiperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hiperproductividad',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}
