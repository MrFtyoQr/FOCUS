import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _firstCtrl  = TextEditingController();
  final _lastCtrl   = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _pass2Ctrl  = TextEditingController();
  bool _obscure     = true;

  @override
  void dispose() { _emailCtrl.dispose(); _firstCtrl.dispose(); _lastCtrl.dispose(); _passCtrl.dispose(); _pass2Ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).register(
      email: _emailCtrl.text.trim(), firstName: _firstCtrl.text.trim(),
      lastName: _lastCtrl.text.trim(), password: _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(authProvider);
    final isLoading = state.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/login'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _field(_emailCtrl, 'Correo', Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                    validator: (v) { if (v == null || v.trim().isEmpty) return 'Requerido'; if (!v.contains('@')) return 'Correo inválido'; return null; }),
                  const SizedBox(height: 14),
                  _field(_firstCtrl, 'Nombre', Icons.person_outline, validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null),
                  const SizedBox(height: 14),
                  _field(_lastCtrl, 'Apellido', Icons.badge_outlined),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl, obscureText: _obscure,
                    decoration: InputDecoration(labelText: 'Contraseña', prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure))),
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Mínimo 8 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pass2Ctrl, obscureText: _obscure,
                    decoration: const InputDecoration(labelText: 'Confirmar contraseña', prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) { if (v != _passCtrl.text) return 'No coincide'; return null; },
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(state.error!, style: const TextStyle(color: AppColors.red, fontSize: 13), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Crear cuenta'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: () => context.go('/login'), child: const Text('Ya tengo cuenta')),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType, FormFieldValidator<String>? validator}) =>
    TextFormField(controller: ctrl, keyboardType: keyboardType, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)), validator: validator);
}
