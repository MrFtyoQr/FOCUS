import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});
  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen> {
  final _pinCtrl = TextEditingController();
  int     _fails    = 0;
  bool    _showPin  = false;
  String? _error;
  static const _maxFails = 3;

  @override
  void initState() { super.initState(); _tryBiometric(); }

  Future<void> _tryBiometric() async {
    final result = await BiometricService.instance.authenticate();
    if (!mounted) return;
    if (result == BiometricResult.success) context.go('/');
    else if (result == BiometricResult.notAvailable) setState(() => _showPin = true);
    else if (result == BiometricResult.lockedOut) ref.read(authProvider.notifier).logout();
  }

  Future<void> _validatePin() async {
    final ok = await BiometricService.instance.validatePin(_pinCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.go('/');
    } else {
      _fails++;
      if (_fails >= _maxFails) { ref.read(authProvider.notifier).logout(); return; }
      setState(() { _error = 'PIN incorrecto. Intentos: ${_maxFails - _fails}'; _pinCtrl.clear(); });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: AppColors.purple, size: 56),
            const SizedBox(height: 24),
            Text('Verifica tu identidad', style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            Text(_showPin ? 'Ingresa tu PIN' : 'Usa biometría para desbloquear', style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
            if (_showPin) ...[
              const SizedBox(height: 32),
              TextField(
                controller: _pinCtrl, keyboardType: TextInputType.number, obscureText: true, maxLength: 6,
                decoration: InputDecoration(hintText: 'PIN', counterText: '', errorText: _error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _validatePin, child: const Text('Confirmar')),
            ] else ...[
              const SizedBox(height: 32),
              TextButton(onPressed: _tryBiometric, child: const Text('Reintentar', style: TextStyle(color: AppColors.purple))),
              TextButton(onPressed: () => setState(() => _showPin = true), child: const Text('Usar PIN', style: TextStyle(color: AppColors.textSecondary))),
            ],
          ],
        ),
      ),
    ),
  );

  @override
  void dispose() { _pinCtrl.dispose(); super.dispose(); }
}
