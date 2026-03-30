import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;

  static const _pages = [
    (icon: Icons.grid_view_rounded,    title: 'Tablero visual',      body: 'Organiza tus actividades en columnas: Bandeja, Hoy, Mañana, Programado y Pendientes.'),
    (icon: Icons.add_circle_outline,   title: 'Captura rápida',      body: 'Agrega nuevas tareas en segundos. Asigna estado, fecha y proyecto sin perder el foco.'),
    (icon: Icons.group_outlined,       title: 'Trabaja en equipo',   body: 'Comparte proyectos, asigna actividades y mide la productividad de tu área.'),
    (icon: Icons.trending_up_rounded,  title: 'Métricas reales',     body: 'Revisa tu ritmo de trabajo y el de tu equipo con estadísticas actualizadas en tiempo real.'),
  ];

  Future<void> _finish() async {
    await LocalPrefs.instance.setOnboardingCompleted();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),
              Icon(p.icon, size: 80, color: AppColors.purple),
              const SizedBox(height: 32),
              Text(p.title,    style: AppTextStyles.heading1, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(p.body,     style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_pages.length, (i) =>
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 20 : 8, height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.purple : AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              )),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _page < _pages.length - 1
                    ? () => setState(() => _page++)
                    : _finish,
                child: Text(_page < _pages.length - 1 ? 'Continuar' : 'Empezar'),
              ),
              if (_page < _pages.length - 1) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: _finish, child: const Text('Saltar', style: TextStyle(color: AppColors.textSecondary))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
