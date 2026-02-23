import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';

/// Pantalla de login: email, contraseña, device_fingerprint al backend.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.onGoToRegister,
  });

  final VoidCallback onLoginSuccess;
  final VoidCallback? onGoToRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    _errorMessage = null;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) widget.onLoginSuccess();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? (e.response!.data['detail'] ?? e.message ?? 'Error de conexión')
          : (e.message ?? 'Error de conexión');
      setState(() {
        _isLoading = false;
        _errorMessage = msg is String ? msg : 'Credenciales inválidas';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer.withOpacity(0.3),
                        colorScheme.secondaryContainer.withOpacity(0.2),
                        colorScheme.tertiaryContainer.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.15,
                      child: Image.asset(
                        'assets/images/hipericon.png',
                        width: isDesktop ? 600 : isTablet ? 400 : 300,
                        height: isDesktop ? 600 : isTablet ? 400 : 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surface.withOpacity(0.85),
                  colorScheme.surface.withOpacity(0.9),
                  colorScheme.surface.withOpacity(0.95),
                ],
              ),
            ),
          ),
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
                      _buildForm(context, isDesktop, isTablet),
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
    final theme = Theme.of(context);
    final logoSize = isDesktop ? 100.0 : isTablet ? 88.0 : 72.0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/hipericon.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
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
        SizedBox(height: 8),
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

  Widget _buildForm(BuildContext context, bool isDesktop, bool isTablet) {
    final theme = Theme.of(context);
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
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'tu@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Indica tu correo';
              if (!v.contains('@') || !v.contains('.')) return 'Correo no válido';
              return null;
            },
            onChanged: (_) => setState(() => _errorMessage = null),
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Indica tu contraseña';
              return null;
            },
            onChanged: (_) => setState(() => _errorMessage = null),
          ),
          if (_errorMessage != null) ...[
            SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: isDesktop ? 28 : 24),
          FilledButton.icon(
            onPressed: _isLoading ? null : _handleLogin,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 18 : isTablet ? 16 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.login, size: 24),
            label: Text(
              _isLoading ? 'Iniciando sesión...' : 'Iniciar sesión',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          Text(
            'Inicia sesión con tu cuenta',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.onGoToRegister != null) ...[
            SizedBox(height: isDesktop ? 16 : 12),
            TextButton.icon(
              onPressed: widget.onGoToRegister,
              icon: const Icon(Icons.person_add_outlined, size: 20),
              label: const Text('¿No tienes cuenta? Regístrate'),
            ),
          ],
        ],
      ),
    );
  }
}
