import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/utils/responsive.dart';

class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});

  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen> {
  final _pinController = TextEditingController();
  int  _failedAttempts = 0;
  static const _maxAttempts = 3;
  bool _showPin  = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    setState(() => _isLoading = true);
    final result = await BiometricService.instance.authenticate();
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case BiometricResult.success:
        context.go('/');
      case BiometricResult.notAvailable:
        setState(() => _showPin = true);
      case BiometricResult.lockedOut:
        _onMaxAttempts();
      case BiometricResult.failure:
        setState(() => _error = 'No se pudo verificar tu identidad');
    }
  }

  Future<void> _validatePin() async {
    setState(() => _isLoading = true);
    final valid = await BiometricService.instance.validatePin(_pinController.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (valid) {
      context.go('/');
    } else {
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        _onMaxAttempts();
      } else {
        setState(() {
          _error = 'PIN incorrecto. Intentos restantes: ${_maxAttempts - _failedAttempts}';
          _pinController.clear();
        });
      }
    }
  }

  void _onMaxAttempts() {
    ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: Responsive.getHorizontalPadding(context)),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: isDesktop ? 400 : double.infinity),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Desbloquea la app',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showPin
                        ? 'Ingresa tu PIN para continuar'
                        : 'Usa biometría para desbloquear',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_showPin) ...[
                    const SizedBox(height: 32),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: 'PIN',
                        counterText: '',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _validatePin,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary),
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Confirmar'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _tryBiometric,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary),
                              ),
                            )
                          : const Icon(Icons.fingerprint, size: 28),
                      label: Text(_isLoading ? 'Verificando...' : 'Desbloquear'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          setState(() {_showPin = true; _error = null;}),
                      child: Text(
                        'Usar PIN',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _onMaxAttempts,
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
