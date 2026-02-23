import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'tablero_screen.dart';
import 'captura_screen.dart';
import 'proyectos_lista_screen.dart';
import 'productividad_screen.dart';
import 'equipo_screen.dart';
import '../core/security/secure_storage.dart';
import '../data/repositories/auth_repository.dart';
import 'admin/admin_panel_screen.dart';
import 'super_admin/usuarios_screen.dart';
import 'super_admin/auditoria_screen.dart';

/// Navegación principal con Bottom Navigation Bar.
/// Conexión y actualizaciones alineadas: al cambiar de pestaña se refrescan datos;
/// al recuperar conectividad se actualiza la pestaña actual.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String _rol = '';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  final List<GlobalKey<State<StatefulWidget>>> _screenKeys = [
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
    GlobalKey<State<StatefulWidget>>(),
  ];

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      TableroScreen(key: _screenKeys[0]),
      CapturaScreen(key: _screenKeys[1]),
      ProyectosListaScreen(key: _screenKeys[2]),
      ProductividadScreen(key: _screenKeys[3]),
      EquipoScreen(key: _screenKeys[4]),
    ]);
    _loadRol();
    _listenConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _listenConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasConnection = results.isNotEmpty && !results.every((r) => r == ConnectivityResult.none);
      if (hasConnection && _wasOffline && mounted) {
        _wasOffline = false;
        _refreshCurrentTab();
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Conectado. Datos actualizados.'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (!hasConnection) {
        _wasOffline = true;
      }
    });
  }

  void _refreshCurrentTab() {
    final state = _screenKeys[_currentIndex].currentState;
    if (state != null) {
      try {
        (state as dynamic).refresh();
      } catch (_) {}
    }
  }

  /// Carga el rol: intenta refrescar desde GET /users/me para que cambios
  /// de rol en la BD se vean sin cerrar sesión; si falla (offline, etc.) usa el guardado.
  Future<void> _loadRol() async {
    try {
      await AuthRepository().refreshUserFromBackend();
    } catch (_) {
      // Sin red o error: usar rol en caché
    }
    if (!mounted) return;
    final r = await SecureStorage().getUserRol();
    if (!mounted) return;
    setState(() => _rol = (r ?? '').trim());
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _rol == 'ADMIN' || _rol == 'SUPER_ADMIN';
    final isSuperAdmin = _rol == 'SUPER_ADMIN';
    return Scaffold(
      appBar: widget.onLogout != null
          ? AppBar(
              title: const Text('HiperApp'),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'logout') widget.onLogout?.call();
                    if (value == 'admin_panel') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                      );
                    }
                    if (value == 'usuarios') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                      );
                    }
                    if (value == 'auditoria') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuditoriaScreen()),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    if (isAdmin)
                      const PopupMenuItem(value: 'admin_panel', child: Text('Panel Admin')),
                    if (isSuperAdmin)
                      const PopupMenuItem(value: 'usuarios', child: Text('Usuarios')),
                    if (isSuperAdmin)
                      const PopupMenuItem(value: 'auditoria', child: Text('Auditoría')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
                  ],
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          // Conexión y actualizaciones: refrescar datos de la pestaña al volver a ella
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final state = _screenKeys[index].currentState;
            if (state != null) {
              try {
                (state as dynamic).refresh();
              } catch (_) {}
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tablero',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Capturar',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Proyectos',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Productividad',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Equipo',
          ),
        ],
      ),
    );
  }
}

