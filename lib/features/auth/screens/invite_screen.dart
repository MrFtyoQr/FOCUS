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
    return 'Al menos un carácter especial';
  }
  return null;
}

class InviteScreen extends ConsumerStatefulWidget {
  final String token;
  const InviteScreen({super.key, required this.token});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _formKey                  = GlobalKey<FormState>();
  final _firstNameController      = TextEditingController();
  final _lastNameController       = TextEditingController();
  final _passwordController       = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _isLoading      = false;
  String? _errorMsg;
  Map<String, dynamic>? _inviteInfo;
  bool _loadingToken   = true;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  Future<void> _validateToken() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final info = await repo.validateInviteToken(widget.token);
      setState(() { _inviteInfo = info; _loadingToken = false; });
    } catch (_) {
      setState(() { _errorMsg = 'El enlace de invitación no es válido o ha expirado.'; _loadingToken = false; });
    }
  }

  Future<void> _handleAccept() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.acceptInvitation(
        token:     widget.token,
        firstName: _firstNameController.text.trim(),
        lastName:  _lastNameController.text.trim(),
        password:  _passwordController.text,
      );
      if (mounted) context.go('/');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg  = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    if (_loadingToken) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMsg != null && _inviteInfo == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Invitación inválida',
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(_errorMsg!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Ir al inicio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Aceptar invitación')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.getHorizontalPadding(context),
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: isDesktop ? 500 : double.infinity),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_inviteInfo?['email'] != null) ...[
                      Text(
                        'Invitación para: ${_inviteInfo!['email']}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                    TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Indica tu nombre' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12))),
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
                            borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Repite la contraseña';
                        if (v != _passwordController.text) {
                          return 'No coincide';
                        }
                        return null;
                      },
                    ),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMsg!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _handleAccept,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary),
                              ),
                            )
                          : const Text('Activar cuenta',
                              style: TextStyle(fontSize: 16)),
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
