import 'package:flutter/material.dart';
import '../../core/security/local_auth.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';

/// Pantalla de desbloqueo: biometría o PIN antes de mostrar contenido sensible.
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({
    super.key,
    required this.onUnlocked,
    required this.onLogout,
  });

  final VoidCallback onUnlocked;
  final VoidCallback onLogout;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final AuthService _authService = AuthService();
  final LocalAuth _localAuth = LocalAuth();
  bool _isLoading = false;
  String? _error;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics().then((available) {
      if (mounted && available) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoUnlock());
      }
    });
  }

  Future<bool> _checkBiometrics() async {
    final available = await _localAuth.hasBiometricsAvailable();
    if (mounted) setState(() => _biometricsAvailable = available);
    return available;
  }

  /// Llamar al abrir la pantalla para mostrar el diálogo nativo de desbloqueo de inmediato.
  void _tryAutoUnlock() {
    if (!_biometricsAvailable || _isLoading) return;
    _unlock();
  }

  Future<void> _unlock() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ok = await _authService.unlockWithBiometrics();
      if (!mounted) return;
      if (ok) {
        await _authService.markUnlocked();
        widget.onUnlocked();
      } else {
        setState(() {
          _isLoading = false;
          _error = 'No se pudo verificar tu identidad';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al desbloquear';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Responsive.getHorizontalPadding(context)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 400 : double.infinity),
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
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usa tu huella o Face ID para continuar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (_biometricsAvailable)
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _unlock,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                              ),
                            )
                          : const Icon(Icons.fingerprint, size: 28),
                      label: Text(_isLoading ? 'Verificando...' : 'Desbloquear'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    )
                  else
                    Text(
                      'No hay biometría disponible en este dispositivo',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => widget.onLogout(),
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
}
