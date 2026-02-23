import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';

/// Reglas de contraseña (alineadas al backend OWASP).
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Indica una contraseña';
  if (value.length < 12) return 'Mínimo 12 caracteres';
  if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Al menos una mayúscula';
  if (!RegExp(r'[a-z]').hasMatch(value)) return 'Al menos una minúscula';
  if (!RegExp(r'[0-9]').hasMatch(value)) return 'Al menos un número';
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
    return 'Al menos un carácter especial (!@#\$%^&*...)';
  }
  return null;
}

/// Pantalla de registro: cualquier usuario puede crearse una cuenta (rol MIEMBRO en backend).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onBackToLogin,
    required this.onRegisterSuccess,
  });

  final VoidCallback onBackToLogin;
  /// Llamado tras registro OK; normalmente volver a login para que inicie sesión.
  final VoidCallback onRegisterSuccess;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    _errorMessage = null;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    // [REG_DEBUG] TODO: retirar cuando se localice el retraso
    final stopwatch = Stopwatch()..start();
    debugPrint('[REG_DEBUG] RegisterScreen: inicio registro ${DateTime.now().toIso8601String()}');
    try {
      await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim().isEmpty ? null : _apellidoController.text.trim(),
      );
      stopwatch.stop();
      debugPrint('[REG_DEBUG] RegisterScreen: registro OK en ${stopwatch.elapsedMilliseconds}ms');
      if (mounted) {
        setState(() => _isLoading = false);
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cuenta creada'),
            content: const Text(
              'Tu cuenta se ha creado correctamente. Ya puedes iniciar sesión.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  widget.onRegisterSuccess();
                },
                child: const Text('Ir a inicio de sesión'),
              ),
            ],
          ),
        );
      }
    } on DioException catch (e) {
      stopwatch.stop();
      // [REG_DEBUG] TODO: retirar
      debugPrint('[REG_DEBUG] RegisterScreen: DioException tras ${stopwatch.elapsedMilliseconds}ms type=${e.type} message=${e.message}');
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout) {
        debugPrint('[REG_DEBUG] RegisterScreen: timeout de conexión/enío - comprobar que el backend esté en la misma red y baseUrl sea alcanzable');
      }
      if (!mounted) return;
      final detail = e.response?.data;
      String msg = 'Error al registrar';
      if (detail is Map && detail['detail'] != null) {
        final d = detail['detail'];
        msg = d is String ? d : d.toString();
      } else if (e.message != null) {
        msg = e.message!;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('[REG_DEBUG] RegisterScreen: excepción tras ${stopwatch.elapsedMilliseconds}ms: $e');
      debugPrint('[REG_DEBUG] RegisterScreen: stack $st');
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
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackToLogin,
        ),
      ),
      body: SafeArea(
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Regístrate para usar HiperApp. Tu cuenta tendrá rol de miembro.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'tu@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Indica tu correo';
                        if (!v.contains('@') || !v.contains('.')) return 'Correo no válido';
                        return null;
                      },
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Indica tu nombre';
                        return null;
                      },
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apellidoController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Apellido (opcional)',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        helperText: 'Mín. 12 caracteres, mayúscula, minúscula, número y símbolo',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: validatePassword,
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Repetir contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Repite la contraseña';
                        if (v != _passwordController.text) return 'No coincide con la contraseña';
                        return null;
                      },
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isDesktop ? 18 : isTablet ? 16 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                              ),
                            )
                          : const Icon(Icons.person_add, size: 24),
                      label: Text(
                        _isLoading ? 'Creando cuenta...' : 'Crear cuenta',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _isLoading ? null : widget.onBackToLogin,
                      icon: const Icon(Icons.login, size: 20),
                      label: const Text('Ya tengo cuenta, iniciar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
