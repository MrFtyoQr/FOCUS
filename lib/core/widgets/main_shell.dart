import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    (path: '/',          label: 'Tablero',       icon: Icons.grid_view_rounded),
    (path: '/capture',   label: 'Capturar',      icon: Icons.add_circle_outline_rounded),
    (path: '/projects',  label: 'Proyectos',     icon: Icons.folder_outlined),
    (path: '/stats',     label: 'Productividad', icon: Icons.trending_up_rounded),
    (path: '/team',      label: 'Equipo',        icon: Icons.group_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final location     = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs
        .indexWhere((t) => t.path == location)
        .clamp(0, _tabs.length - 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => context.go(_tabs[i].path),
          items: _tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
