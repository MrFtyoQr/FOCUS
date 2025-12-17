import 'package:flutter/material.dart';
import 'tablero_screen.dart';
import 'captura_screen.dart';
import 'proyectos_lista_screen.dart';
import 'productividad_screen.dart';
import 'equipo_screen.dart';

/// Navegación principal con Bottom Navigation Bar
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<GlobalKey> _screenKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Recargar datos cuando se vuelve al Tablero
          if (index == 0) {
            // El Tablero se recargará automáticamente al ser visible
          }
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

