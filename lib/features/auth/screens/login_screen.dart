import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey            = GlobalKey<FormState>();
  final _emailCtrl          = TextEditingController();
  final _passwordCtrl       = TextEditingController();
  bool  _obscure            = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(authProvider);
    final isLoading = state.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo / header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset('assets/images/hipericon.png', width: 72, height: 72,
                          errorBuilder: (_, __, ___) => const Icon(Icons.bolt_rounded, size: 72, color: AppColors.purple)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('HiperApp', style: AppTextStyles.heading1, textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text('Sistema de Hiperproductividad', style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
                    const SizedBox(height: 40),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                      decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Indica tu correo';
                        if (!v.contains('@')) return 'Correo no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Indica tu contraseña' : null,
                    ),

                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(state.error!, style: const TextStyle(color: AppColors.red, fontSize: 13), textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('¿No tienes cuenta? Regístrate'),
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
