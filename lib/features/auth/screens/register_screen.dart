import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/utils/responsive.dart';

String? _validatePassword(String? value) {
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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey                  = GlobalKey<FormState>();
  final _emailController          = TextEditingController();
  final _passwordController       = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController      = TextEditingController();
  final _lastNameController       = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();

    await ref.read(authProvider.notifier).register(
      email:     _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName:  _lastNameController.text.trim(),
      password:  _passwordController.text,
    );

    // Si registro exitoso, GoRouter redirige automáticamente
  }

  @override
  Widget build(BuildContext context) {
    final authState  = ref.watch(authProvider);
    final isLoading  = authState.status == AuthStatus.loading;
    final errorMsg   = authState.error;
    final theme      = Theme.of(context);
    final isDesktop  = Responsive.isDesktop(context);
    final isTablet   = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
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
                          color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      onChanged: (_) =>
                          ref.read(authProvider.notifier).clearError(),
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'tu@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Indica tu correo';
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Correo no válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Indica tu nombre';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Apellido (opcional)',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        helperText:
                            'Mín. 12 caracteres, mayúscula, minúscula, número y símbolo',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Repetir contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_off : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Repite la contraseña';
                        if (v != _passwordController.text) {
                          return 'No coincide con la contraseña';
                        }
                        return null;
                      },
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMsg,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: isLoading ? null : _handleRegister,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: isDesktop ? 18 : isTablet ? 16 : 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
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
                          : const Icon(Icons.person_add, size: 24),
                      label: Text(
                        isLoading ? 'Creando cuenta...' : 'Crear cuenta',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: isLoading ? null : () => context.go('/login'),
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
