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
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.grid_view_rounded,
      title: 'Tu tablero de actividades',
      body: 'Organiza tus tareas del día en columnas: Hoy, Mañana, Programado y Bandeja.',
    ),
    _OnboardingPage(
      icon: Icons.add_circle_outline_rounded,
      title: 'Captura al instante',
      body: 'Crea actividades en segundos desde cualquier pantalla sin perder el hilo.',
    ),
    _OnboardingPage(
      icon: Icons.trending_up_rounded,
      title: 'Mide tu productividad',
      body: 'Revisa tus estadísticas personales y de equipo para mejorar cada semana.',
    ),
  ];

  Future<void> _finish() async {
    await LocalPrefs.instance.setOnboardingCompleted();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width:  _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.purple
                              : AppColors.surfaceBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLast
                          ? _finish
                          : () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                      child: Text(isLast ? 'Empezar' : 'Siguiente'),
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Omitir',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: AppColors.purple),
          ),
          const SizedBox(height: 32),
          Text(title, style: AppTextStyles.heading1, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            body,
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
