import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'utils/app_theme.dart';
import 'screens/main_navigation.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔑 IMPORTANTE: Inicializar SQLite para Windows / Desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializar timezone
  tz.initializeTimeZones();

  // Inicializar base de datos
  await DatabaseService().initialize();

  // Inicializar y programar notificaciones
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.programarNotificacionesDiarias();
  } catch (e) {
    print('Error al inicializar notificaciones: $e');
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
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}
