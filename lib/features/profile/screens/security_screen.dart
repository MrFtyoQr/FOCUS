import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _biometricEnabled  = false;
  bool _biometricAvailable = false;
  bool _isLoading          = false;

  final _pinController        = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _pinError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await BiometricService.instance.isAvailable();
    final enabled   = await LocalPrefs.instance.isBiometricEnabled();
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled   = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_biometricAvailable) return;
    setState(() => _isLoading = true);

    if (value) {
      final result = await BiometricService.instance.authenticate();
      if (!mounted) return;
      if (result == BiometricResult.success) {
        await LocalPrefs.instance.setBiometricEnabled(true);
        setState(() { _biometricEnabled = true; _isLoading = false; });
        _showSnack('Biometría activada');
      } else {
        setState(() => _isLoading = false);
        _showSnack('No se pudo verificar la biometría');
      }
    } else {
      await LocalPrefs.instance.setBiometricEnabled(false);
      setState(() { _biometricEnabled = false; _isLoading = false; });
      _showSnack('Biometría desactivada');
    }
  }

  Future<void> _savePin() async {
    final pin     = _pinController.text;
    final confirm = _confirmPinController.text;

    if (pin.length < 4) {
      setState(() => _pinError = 'El PIN debe tener al menos 4 dígitos');
      return;
    }
    if (pin != confirm) {
      setState(() => _pinError = 'Los PINs no coinciden');
      return;
    }

    setState(() => _isLoading = true);
    await BiometricService.instance.savePin(pin);
    setState(() { _isLoading = false; _pinError = null; });
    _pinController.clear();
    _confirmPinController.clear();
    _showSnack('PIN guardado correctamente');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seguridad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Biometría ──
          Text('Desbloqueo biométrico', style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          Text(
            'Usa tu huella o Face ID para desbloquear la app.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
            ),
            child: SwitchListTile(
              value: _biometricEnabled,
              onChanged: _isLoading || !_biometricAvailable
                  ? null
                  : _toggleBiometric,
              title: Text(
                _biometricAvailable
                    ? 'Activar biometría'
                    : 'No disponible en este dispositivo',
                style: AppTextStyles.body,
              ),
              activeThumbColor: AppColors.purple,
            ),
          ),
          const SizedBox(height: 32),
          const Divider(color: AppColors.surfaceBorder),
          const SizedBox(height: 24),

          // ── PIN ──
          Text('PIN de respaldo', style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          Text(
            'El PIN se usa cuando la biometría no está disponible.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 8,
            decoration: InputDecoration(
              labelText: 'Nuevo PIN',
              counterText: '',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 8,
            decoration: InputDecoration(
              labelText: 'Confirmar PIN',
              counterText: '',
              errorText: _pinError,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _savePin,
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar PIN'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}
