import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/utils/responsive.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  final _formKey           = GlobalKey<FormState>();
  final _emailController   = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).login(
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState   = ref.watch(authProvider);
    final isLoading   = authState.status == AuthStatus.loading;
    final errorMsg    = authState.error;
    final isDesktop   = Responsive.isDesktop(context);
    final isTablet    = Responsive.isTablet(context);
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo animado
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) => Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.3),
                      colorScheme.secondaryContainer.withValues(alpha: 0.2),
                      colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.asset(
                      'assets/images/hipericon.png',
                      width:  isDesktop ? 600 : isTablet ? 400 : 300,
                      height: isDesktop ? 600 : isTablet ? 400 : 300,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Overlay de gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surface.withValues(alpha: 0.85),
                  colorScheme.surface.withValues(alpha: 0.90),
                  colorScheme.surface.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
          // Contenido
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.getHorizontalPadding(context),
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 500 : isTablet ? 450 : double.infinity,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context, isDesktop, isTablet),
                      SizedBox(height: isDesktop ? 40 : isTablet ? 32 : 24),
                      _buildForm(context, isDesktop, isTablet, isLoading, errorMsg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop, bool isTablet) {
    final theme    = Theme.of(context);
    final logoSize = isDesktop ? 100.0 : isTablet ? 88.0 : 72.0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 20, spreadRadius: 5,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/hipericon.png',
            width: logoSize, height: logoSize, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.bolt_rounded,
              size: logoSize,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 24 : isTablet ? 20 : 16),
        Text(
          'HiperApp',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sistema de Hiperproductividad',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
    bool isLoading,
    String? errorMsg,
  ) {
    final theme    = Theme.of(context);
    final fontSize = isDesktop ? 18.0 : isTablet ? 17.0 : 16.0;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            onChanged: (_) => ref.read(authProvider.notifier).clearError(),
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'tu@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Indica tu correo';
              if (!v.contains('@') || !v.contains('.')) return 'Correo no válido';
              return null;
            },
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) => ref.read(authProvider.notifier).clearError(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Indica tu contraseña';
              return null;
            },
          ),
          if (errorMsg != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMsg,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: isDesktop ? 28 : 24),
          FilledButton.icon(
            onPressed: isLoading ? null : _handleLogin,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                  vertical: isDesktop ? 18 : isTablet ? 16 : 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            icon: isLoading
                ? SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary),
                    ),
                  )
                : const Icon(Icons.login, size: 24),
            label: Text(
              isLoading ? 'Iniciando sesión...' : 'Iniciar sesión',
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          Text(
            'Inicia sesión con tu cuenta',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          TextButton.icon(
            onPressed: () => context.go('/register'),
            icon: const Icon(Icons.person_add_outlined, size: 20),
            label: const Text('¿No tienes cuenta? Regístrate'),
          ),
        ],
      ),
    );
  }
}
