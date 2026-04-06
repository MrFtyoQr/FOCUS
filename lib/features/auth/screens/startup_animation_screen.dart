import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../core/theme/app_colors.dart';

/// Texto→focus sin fundido; targets solo con fundido suave (sin zoom/blur).
class StartupAnimationScreen extends ConsumerStatefulWidget {
  const StartupAnimationScreen({super.key});

  @override
  ConsumerState<StartupAnimationScreen> createState() =>
      _StartupAnimationScreenState();
}

class _StartupAnimationScreenState extends ConsumerState<StartupAnimationScreen>
    with TickerProviderStateMixin {
  static const _suffixes = <String>['', 'LOW', 'ORWARD', 'ORGE', 'INISH', 'OCUS'];

  static const _delayBeforeSlideLeft = Duration(milliseconds: 320);
  static const _slideFToEdgeDuration = Duration(milliseconds: 600);
  static const _stepDuration = Duration(milliseconds: 560);
  static const _suffixSwitchDuration = Duration(milliseconds: 420);
  static const _holdBeforeFocusSlide = Duration(milliseconds: 380);
  static const _slideFocusCenterDuration = Duration(milliseconds: 780);
  static const _holdAfterCenter = Duration(milliseconds: 640);

  static const _edgePadding = 24.0;
  static const _focusImageAsset1 = 'assets/images/focus1.png';
  static const _focusImageAsset2 = 'assets/images/focus2.png';
  static const _targetAssets = <String>[
    'assets/images/target1.png',
    'assets/images/target2.png',
    'assets/images/target3.png',
    'assets/images/target4.png',
  ];
  /// Sin cruce visible: corte en el instante del cambio (texto ↔ imagen focus).
  static const _textToImageCrossfade = Duration.zero;
  static const _focus1To2Crossfade = Duration(milliseconds: 680);
  /// Desvanecimiento de `focus2` mientras entra `target1` (solapado).
  static const _focus2FadeOutDuration = Duration(milliseconds: 900);
  /// Entrada del target: desliz + fade, en paralelo al fade de focus2.
  static const _targetEnterDuration = Duration(milliseconds: 880);
  /// Tras centrado: pasa a 300 % del tamaño base (×3).
  static const _targetScaleDuration = Duration(milliseconds: 780);
  /// Cruce entre imágenes target (solo opacidad, sin escala ni desenfoque).
  static const _targetSwapDuration = Duration(milliseconds: 780);
  /// Tiempo extra con `target3` visible antes de pasar a `target4`.
  static const _targetExtraHoldOn3 = Duration(milliseconds: 1150);
  static const _targetSlideFromLeftPx = 35.0;
  /// Altura respecto a [slotH] (0,5 × 1,3 ≈ +30 % sobre la mitad del logo).
  static const _targetHeightFactor = 0.65;
  /// Logo respecto al bounding box del texto «FOCUS» medido.
  static const _focusLogoScale = 1.25;

  late final AnimationController _fToLeftController;
  late final AnimationController _focusCenterController;
  late final AnimationController _focusFadeOutController;
  late final AnimationController _targetEntryController;
  late final AnimationController _targetScaleController;

  Timer? _suffixTimer;
  int _step = 0;
  bool _focusSlideActive = false;
  /// Muestra el overlay del target mientras `focus2` aún se desvanece.
  bool _targetLayerVisible = false;
  /// 1…4 → [_targetAssets] índice 0…3 (tras escalar, avanza 2→3→4).
  int _targetVariant = 1;

  @override
  void initState() {
    super.initState();
    _fToLeftController = AnimationController(
      vsync: this,
      duration: _slideFToEdgeDuration,
    );
    _focusCenterController = AnimationController(
      vsync: this,
      duration: _slideFocusCenterDuration,
    );
    _focusFadeOutController = AnimationController(
      vsync: this,
      duration: _focus2FadeOutDuration,
    );
    _targetEntryController = AnimationController(
      vsync: this,
      duration: _targetEnterDuration,
    );
    _targetScaleController = AnimationController(
      vsync: this,
      duration: _targetScaleDuration,
    );

    _fToLeftController.addStatusListener(_onFSlideStatus);
    _focusCenterController.addStatusListener(_onFocusCenterStatus);
    _targetEntryController.addStatusListener(_onTargetEntryStatus);
    _targetScaleController.addStatusListener(_onTargetScaleStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(_delayBeforeSlideLeft, () {
        if (mounted) _fToLeftController.forward();
      });
    });
  }

  void _onFSlideStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _startSuffixSequence();
    }
  }

  void _onFocusCenterStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    Future<void>.delayed(_focus1To2Crossfade, () {
      if (!mounted) return;
      setState(() => _targetLayerVisible = true);
      _focusFadeOutController.forward(from: 0);
      _targetEntryController.forward(from: 0);
    });
    final overlapEnd = math.max(
      _focus2FadeOutDuration.inMilliseconds,
      _targetEnterDuration.inMilliseconds,
    );
    // Tras escala: 3 esperas hasta variant 4 + tiempo extra en 3 + último cruce 3→4.
    final targetTail = _targetScaleDuration.inMilliseconds +
        4 * _targetSwapDuration.inMilliseconds +
        _targetExtraHoldOn3.inMilliseconds;
    final beforeNav = _focus1To2Crossfade +
        Duration(milliseconds: overlapEnd) +
        Duration(milliseconds: targetTail) +
        _holdAfterCenter;
    Future<void>.delayed(beforeNav, () async {
      if (!mounted) return;
      await _goNext();
    });
  }

  void _onTargetEntryStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _targetScaleController.forward(from: 0);
    }
  }

  void _onTargetScaleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      unawaited(_advanceTargetVariantsAfterScale());
    }
  }

  Future<void> _advanceTargetVariantsAfterScale() async {
    await Future<void>.delayed(_targetSwapDuration);
    if (!mounted) return;
    setState(() => _targetVariant = 2);
    await Future<void>.delayed(_targetSwapDuration);
    if (!mounted) return;
    setState(() => _targetVariant = 3);
    await Future<void>.delayed(_targetSwapDuration + _targetExtraHoldOn3);
    if (!mounted) return;
    setState(() => _targetVariant = 4);
  }

  void _startSuffixSequence() {
    _suffixTimer?.cancel();
    _suffixTimer = Timer.periodic(_stepDuration, (t) {
      if (!mounted) return;
      if (_step < _suffixes.length - 1) {
        setState(() => _step++);
      } else {
        t.cancel();
        Future<void>.delayed(_holdBeforeFocusSlide, () {
          if (!mounted) return;
          setState(() => _focusSlideActive = true);
          _focusCenterController.forward(from: 0);
        });
      }
    });
  }

  @override
  void dispose() {
    _suffixTimer?.cancel();
    _fToLeftController
      ..removeStatusListener(_onFSlideStatus)
      ..dispose();
    _focusCenterController
      ..removeStatusListener(_onFocusCenterStatus)
      ..dispose();
    _focusFadeOutController.dispose();
    _targetEntryController
      ..removeStatusListener(_onTargetEntryStatus)
      ..dispose();
    _targetScaleController
      ..removeStatusListener(_onTargetScaleStatus)
      ..dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    final auth = ref.read(authProvider);
    final router = GoRouter.of(context);

    switch (auth.status) {
      case AuthStatus.loading:
        router.go('/loading');
        break;
      case AuthStatus.unauthenticated:
        router.go('/login', extra: true);
        break;
      case AuthStatus.authenticated:
        final onboardingDone = await LocalPrefs.instance.isOnboardingCompleted();
        if (!mounted) return;
        router.go(onboardingDone ? '/' : '/onboarding');
        break;
    }
  }

  TextStyle _wordStyle(double fontSize) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: fontSize * 0.03,
        height: 1.0,
      );

  /// Sufijo: entra desde la F (desliza a la derecha) y sale hacia la F (desliza a la izquierda).
  /// Sin bounce; fade suave. [animation] 0→1 entrada, 1→0 salida (reversa).
  Widget _suffixTransition(Widget child, Animation<double> animation) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.68, curve: Curves.easeInOutCubic),
      reverseCurve: const Interval(0.32, 1, curve: Curves.easeInOutCubic),
    );
    final slide = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    // Posición relativa al hijo: negativo X = hacia la F (izquierda del sufijo).
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.22, 0),
          end: Offset.zero,
        ).animate(slide),
        child: child,
      ),
    );
  }

  /// Solo fundido entre targets (sin blur ni escala → evita sensación de zoom).
  Widget _targetSoftCrossfade(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
        reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
      ),
      child: child,
    );
  }

  /// Overlay a pantalla completa para permitir escala ×3 sin recortar.
  Widget _buildTargetOverlay(double baseImageHeight) {
    final idx = (_targetVariant - 1).clamp(0, _targetAssets.length - 1);
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _targetEntryController,
              _targetScaleController,
            ]),
            builder: (context, _) {
              final entryT = Curves.easeOutCubic
                  .transform(_targetEntryController.value);
              final dx = lerpDouble(-_targetSlideFromLeftPx, 0, entryT)!;
              final scale = _targetEntryController.isCompleted
                  ? lerpDouble(
                      1.0,
                      3.0,
                      Curves.easeOutCubic.transform(
                        _targetScaleController.value,
                      ),
                    )!
                  : 1.0;
              return Opacity(
                opacity: entryT,
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: _targetSwapDuration,
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: _targetSoftCrossfade,
                      layoutBuilder: (current, previous) {
                        return Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          fit: StackFit.passthrough,
                          children: [
                            ...previous,
                            if (current != null) current,
                          ],
                        );
                      },
                      child: Image.asset(
                        _targetAssets[idx],
                        key: ValueKey<int>(_targetVariant),
                        height: baseImageHeight,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final fontSize = w < 360 ? 28.0 : w < 600 ? 36.0 : 44.0;
    final style = _wordStyle(fontSize);
    final suffix = _suffixes[_step];

    final fPainter = TextPainter(
      text: TextSpan(text: 'F', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final focusPainter = TextPainter(
      text: TextSpan(text: 'FOCUS', style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final fWidth = fPainter.width;
    final focusWidth = focusPainter.width;
    final lineHeight = fPainter.height;
    final slotH = lineHeight * _focusLogoScale;
    final focusLogoWidth = focusWidth * _focusLogoScale;
    final top = (h - slotH) / 2;

    final centerFLeft = (w - fWidth) / 2;
    final pad = _edgePadding;
    final focusCenterLeft = (w - focusLogoWidth) / 2;

    final ease = Curves.easeInOutCubic;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnimatedBuilder(
          animation: Listenable.merge([
            _fToLeftController,
            _focusCenterController,
            _focusFadeOutController,
            _targetEntryController,
            _targetScaleController,
          ]),
          builder: (context, _) {
            double rowLeft;
            if (!_fToLeftController.isCompleted) {
              final t = ease.transform(_fToLeftController.value);
              rowLeft = lerpDouble(centerFLeft, pad, t)!;
            } else if (!_focusSlideActive) {
              rowLeft = pad;
            } else {
              final t = ease.transform(_focusCenterController.value);
              rowLeft = lerpDouble(pad, focusCenterLeft, t)!;
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: top,
                  height: slotH,
                  child: AnimatedSwitcher(
                    duration: _textToImageCrossfade,
                    switchInCurve: Curves.linear,
                    switchOutCurve: Curves.linear,
                    transitionBuilder: (child, animation) => child,
                    layoutBuilder: (current, previous) {
                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        fit: StackFit.expand,
                        children: [
                          ...previous,
                          if (current != null) current,
                        ],
                      );
                    },
                    child: _focusSlideActive
                        ? Stack(
                            key: const ValueKey<String>('phase_focus_stack'),
                            clipBehavior: Clip.none,
                            fit: StackFit.expand,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: rowLeft),
                                  child: FadeTransition(
                                    opacity: Tween<double>(begin: 1, end: 0)
                                        .animate(
                                      CurvedAnimation(
                                        parent: _focusFadeOutController,
                                        curve: Curves.easeInOutCubic,
                                      ),
                                    ),
                                    child: SizedBox(
                                      width: focusLogoWidth,
                                      height: slotH,
                                      child: AnimatedSwitcher(
                                        duration: _focus1To2Crossfade,
                                        switchInCurve: Curves.easeInOutCubic,
                                        switchOutCurve: Curves.easeInOutCubic,
                                        transitionBuilder: (child, animation) =>
                                            FadeTransition(
                                                opacity: animation,
                                                child: child),
                                        layoutBuilder: (current, previous) {
                                          return Stack(
                                            alignment: Alignment.center,
                                            fit: StackFit.expand,
                                            clipBehavior: Clip.none,
                                            children: [
                                              ...previous,
                                              if (current != null) current,
                                            ],
                                          );
                                        },
                                        child: Image.asset(
                                          _focusCenterController.isCompleted
                                              ? _focusImageAsset2
                                              : _focusImageAsset1,
                                          key: ValueKey<bool>(
                                            _focusCenterController.isCompleted,
                                          ),
                                          fit: BoxFit.contain,
                                          alignment: Alignment.center,
                                          filterQuality: FilterQuality.high,
                                          gaplessPlayback: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Align(
                                key: const ValueKey<String>('phase_text'),
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: rowLeft),
                                  child: SizedBox(
                                    height: slotH,
                                    child: Align(
                                      alignment: Alignment.bottomLeft,
                                      child: SizedBox(
                                        height: lineHeight,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text('F', style: style),
                                            SizedBox(
                                              height: lineHeight,
                                              child: AnimatedSwitcher(
                                                duration: _suffixSwitchDuration,
                                                switchInCurve:
                                                    Curves.easeInOutCubic,
                                                switchOutCurve:
                                                    Curves.easeInOutCubic,
                                                transitionBuilder:
                                                    _suffixTransition,
                                                layoutBuilder:
                                                    (current, previous) {
                                                  return Stack(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    clipBehavior: Clip.none,
                                                    children: [
                                                      ...previous,
                                                      if (current != null)
                                                        current,
                                                    ],
                                                  );
                                                },
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    suffix,
                                                    key: ValueKey<String>(
                                                        suffix),
                                                    style: style,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                  ),
                ),
                if (_targetLayerVisible)
                  _buildTargetOverlay(slotH * _targetHeightFactor),
              ],
            );
          },
        ),
      ),
    );
  }
}
