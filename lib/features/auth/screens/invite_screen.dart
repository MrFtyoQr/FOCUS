import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class InviteScreen extends ConsumerStatefulWidget {
  final String token;
  const InviteScreen({super.key, required this.token});
  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool  _obscure   = true;

  @override
  void dispose() { _firstCtrl.dispose(); _lastCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _accept() async {
    if (!_formKey.currentState!.validate()) return;
    // En producción llamaría al repo; aquí solo navega al login
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Aceptar invitación')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(controller: _firstCtrl, decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _lastCtrl, decoration: const InputDecoration(labelText: 'Apellido', prefixIcon: Icon(Icons.badge_outlined))),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passCtrl, obscureText: _obscure,
              decoration: InputDecoration(labelText: 'Contraseña', prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure))),
              validator: (v) => (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _accept, child: const Text('Crear cuenta y entrar')),
          ]),
        ),
      ),
    ),
  );
}
