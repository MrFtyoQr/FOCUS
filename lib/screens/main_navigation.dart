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
  static const double _iconSize = 28.0;
  static const double _selectedIconSize = 31.0;
  static const double _selectorSize = 58.0;
  /// Misma elevación para ícono seleccionado y círculo (centrados a la misma altura).
  static const double _selectedLift = -15.0;
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
      ProductividadScreen(key: _screenKeys[1]),
      CapturaScreen(key: _screenKeys[2]),
      ProyectosListaScreen(key: _screenKeys[3]),
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
      bottomNavigationBar: _buildCustomTabBar(context),
    );
  }

  Widget _buildCustomTabBar(BuildContext context) {
    const icons = [
      Icons.dashboard_outlined,
      Icons.insights_outlined,
      Icons.add_circle_outline,
      Icons.folder_outlined,
      Icons.people_outline,
    ];
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 70,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / icons.length;
            final selectorLeft =
                (_currentIndex * tabWidth) + ((tabWidth - _selectorSize) / 2);

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  top: _selectedLift + 6,
                  left: selectorLeft,
                  child: Container(
                    width: _selectorSize,
                    height: _selectorSize,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(icons.length, (index) {
                    final selected = index == _currentIndex;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _currentIndex = index),
                        child: Transform.translate(
                          offset: Offset(0, selected ? _selectedLift : 0),
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            scale: selected ? 1.05 : 1.0,
                            child: Icon(
                              icons[index],
                              size: selected ? _selectedIconSize : _iconSize,
                              color: selected
                                  ? _selectedTabIconColorFor(context)
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Ícono del tab seleccionado: #EAEAEA en claro; #1A1A1A en oscuro (sin cambiar dark).
  static const Color _selectedTabIconDarkMode = Color(0xFF1A1A1A);
  static const Color _selectedTabIconLightMode = Color(0xFFEAEAEA);

  Color _selectedTabIconColorFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _selectedTabIconLightMode
        : _selectedTabIconDarkMode;
  }
}

