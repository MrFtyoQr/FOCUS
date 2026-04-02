import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell principal: barra inferior personalizada + cuerpo desde [GoRouter].
///
/// Orden de pestañas (igual que el legacy MainNavigation): tablero, productividad,
/// captura, proyectos, equipo.
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const double _iconSize = 28.0;
  static const double _selectedIconSize = 31.0;
  static const double _selectorSize = 58.0;
  static const double _selectedLift = -15.0;

  static const Color _selectedTabIconDarkMode = Color(0xFF1A1A1A);
  static const Color _selectedTabIconLightMode = Color(0xFFEAEAEA);

  /// Rutas raíz de cada pestaña (índice alineado con [_icons]).
  static const List<String> tabPaths = [
    '/',
    '/stats',
    '/capture',
    '/projects',
    '/team',
  ];

  static const List<IconData> _icons = [
    Icons.dashboard_outlined,
    Icons.insights_outlined,
    Icons.add_circle_outline,
    Icons.folder_outlined,
    Icons.people_outline,
  ];

  static int _tabIndexForLocation(String location) {
    if (location.startsWith('/team')) return 4;
    if (location.startsWith('/projects')) return 3;
    if (location.startsWith('/capture')) return 2;
    if (location.startsWith('/stats')) return 1;
    return 0;
  }

  Color _selectedTabIconColorFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _selectedTabIconLightMode
        : _selectedTabIconDarkMode;
  }

  Widget _buildCustomTabBar(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _tabIndexForLocation(location);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 70,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / _icons.length;
            final selectorLeft =
                (currentIndex * tabWidth) + ((tabWidth - _selectorSize) / 2);

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
                  children: List.generate(_icons.length, (index) {
                    final selected = index == currentIndex;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.go(tabPaths[index]),
                        child: Transform.translate(
                          offset: Offset(0, selected ? _selectedLift : 0),
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            scale: selected ? 1.05 : 1.0,
                            child: Icon(
                              _icons[index],
                              size:
                                  selected ? _selectedIconSize : _iconSize,
                              color: selected
                                  ? _selectedTabIconColorFor(context)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildCustomTabBar(context),
    );
  }
}
