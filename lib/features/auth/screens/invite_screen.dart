import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../../../core/utils/responsive.dart';

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Indica una contraseña';
  if (value.length < 8) return 'Mínimo 8 caracteres';
  if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Al menos una mayúscula';
  if (!RegExp(r'[a-z]').hasMatch(value)) return 'Al menos una minúscula';
  if (!RegExp(r'[0-9]').hasMatch(value)) return 'Al menos un número';
  return null;
}

enum _JoinStep { enterCode, fillData }

/// Pantalla para aceptar una invitación.
///
/// Si [token] está vacío (ruta `/join`) muestra el paso de ingreso de código
/// y lo verifica contra el backend antes de continuar.
///
/// Si viene pre-cargado (ruta `/invite/:token`) intenta verificarlo
/// automáticamente al montar.
class InviteScreen extends ConsumerStatefulWidget {
  final String token;
  const InviteScreen({super.key, required this.token});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  // ── Pasos ────────────────────────────────────────────────────────────────
  late _JoinStep  _step;
  late String     _resolvedCode;
  InviteInfo?     _inviteInfo;

  // ── Paso 1 ───────────────────────────────────────────────────────────────
  final _codeFormKey = GlobalKey<FormState>();
  final _codeCtrl    = TextEditingController();
  bool    _verifying  = false;
  String? _codeError;

  // ── Paso 2 ───────────────────────────────────────────────────────────────
  final _regFormKey                = GlobalKey<FormState>();
  final _emailController           = TextEditingController();
  final _firstNameController       = TextEditingController();
  final _lastNameController        = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool    _obscurePassword = true;
  bool    _obscureConfirm  = true;
  bool    _isLoading       = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final preloaded = widget.token.trim();
    if (preloaded.isNotEmpty) {
      _step          = _JoinStep.enterCode; // se verificará automáticamente
      _resolvedCode  = preloaded;
      _codeCtrl.text = preloaded;
      WidgetsBinding.instance.addPostFrameCallback((_) => _verifyCode());
    } else {
      _step         = _JoinStep.enterCode;
      _resolvedCode = '';
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Lógica ────────────────────────────────────────────────────────────────

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _codeError = 'Ingresa el código de invitación');
      return;
    }
    setState(() { _verifying = true; _codeError = null; });
    try {
      final repo = ref.read(authRepositoryProvider);
      final info = await repo.verifyInviteCode(code);
      if (!mounted) return;
      setState(() {
        _verifying    = false;
        _resolvedCode = code;
        _inviteInfo   = info;
        _step         = _JoinStep.fillData;
        _errorMsg     = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _codeError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onContinue() {
    if (!_codeFormKey.currentState!.validate()) return;
    _verifyCode();
  }

  Future<void> _handleAccept() async {
    if (!_regFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.acceptInvitation(
        code:      _resolvedCode,
        email:     _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName:  _lastNameController.text.trim(),
        password:  _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Cuenta creada! Ya puedes iniciar sesión.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg  = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _step == _JoinStep.enterCode ? 'Unirse al equipo' : 'Crear cuenta',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == _JoinStep.fillData && widget.token.trim().isEmpty) {
              setState(() {
                _step     = _JoinStep.enterCode;
                _errorMsg = null;
              });
            } else {
              context.go('/login');
            }
          },
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
                  maxWidth: isDesktop ? 500 : double.infinity),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _step == _JoinStep.enterCode
                    ? _buildCodeStep(theme)
                    : _buildRegistrationStep(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Paso 1: ingresa y verifica el código ─────────────────────────────────

  Widget _buildCodeStep(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Form(
      key: _codeFormKey,
      child: Column(
        key: const ValueKey('step-code'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.key_outlined, size: 56, color: scheme.primary),
          const SizedBox(height: 16),
          Text(
            'Ingresa tu código',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tu administrador te compartió un código de invitación. '
            'Pégalo aquí para unirte al equipo.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // ── Campo del código ─────────────────────────────────────────────
          TextFormField(
            controller: _codeCtrl,
            autocorrect: false,
            enableSuggestions: false,
            maxLines: 2,
            minLines: 1,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 0.4,
            ),
            decoration: InputDecoration(
              labelText: 'Código de invitación',
              hintText: 'Pega aquí el código...',
              prefixIcon: const Icon(Icons.vpn_key_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              errorText: _codeError,
              // Botón para pegar desde portapapeles
              suffixIcon: IconButton(
                tooltip: 'Pegar del portapapeles',
                icon: const Icon(Icons.content_paste_rounded),
                onPressed: () async {
                  final data =
                      await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null && mounted) {
                    setState(() {
                      _codeCtrl.text = data!.text!.trim();
                      _codeError     = null;
                    });
                  }
                },
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Pega o escribe el código de invitación';
              }
              return null;
            },
            onFieldSubmitted: (_) => _onContinue(),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _verifying ? null : _onContinue,
            icon: _verifying
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.arrow_forward),
            label: Text(_verifying ? 'Verificando...' : 'Continuar'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Volver al inicio de sesión'),
          ),
        ],
      ),
    );
  }

  // ── Paso 2: datos de registro ────────────────────────────────────────────

  Widget _buildRegistrationStep(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Form(
      key: _regFormKey,
      child: Column(
        key: const ValueKey('step-reg'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Banner de invitación verificada ──────────────────────────────
          if (_inviteInfo != null)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_outlined,
                      color: scheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código verificado',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _inviteInfo!.areaName != null
                              ? '${_inviteInfo!.roleLabel} · ${_inviteInfo!.areaName}'
                              : _inviteInfo!.roleLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        if (_inviteInfo!.expiresAt != null)
                          Text(
                            'Expira: ${_inviteInfo!.expiresAt}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Text(
            'Completa tu perfil',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Correo
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico *',
              hintText: 'tu@email.com',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Indica tu correo';
              if (!v.contains('@') || !v.contains('.')) {
                return 'Correo no válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Nombre
          TextFormField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre *',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Indica tu nombre' : null,
          ),
          const SizedBox(height: 14),

          // Apellido
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
          const SizedBox(height: 14),

          // Contraseña
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña *',
              helperText: 'Mín. 8 caracteres, mayúscula, minúscula y número',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 14),

          // Confirmar contraseña
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Repetir contraseña *',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Repite la contraseña';
              if (v != _passwordController.text) return 'No coincide';
              return null;
            },
          ),

          // Error del servidor
          if (_errorMsg != null) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMsg!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _isLoading ? null : _handleAccept,
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(_isLoading ? 'Creando cuenta...' : 'Activar cuenta'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
