import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// El registro de usuarios en HiperApp se realiza exclusivamente mediante
/// invitación. Esta pantalla informa al usuario y lo redirige al login.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline,
                    size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  'Registro por invitación',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Para crear tu cuenta necesitas un enlace de invitación '
                  'enviado por tu administrador.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Ir al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
