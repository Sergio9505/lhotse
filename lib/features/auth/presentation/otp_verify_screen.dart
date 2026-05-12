import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../data/auth_repository.dart';
import 'widgets/lhotse_otp_field.dart';
import 'widgets/lhotse_submit_button.dart';

enum OtpPurpose { passwordRecovery, signupVerification }

class OtpVerifyArgs {
  const OtpVerifyArgs({required this.phone, required this.purpose});

  final String phone;
  final OtpPurpose purpose;
}

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, required this.args});

  final OtpVerifyArgs args;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  static const _resendCooldownSeconds = 30;

  final _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;
  int _secondsRemaining = _resendCooldownSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  Future<void> _verify() async {
    final token = _otpController.text.trim();
    if (token.length != 6) {
      setState(() => _errorMessage = 'Introduce los 6 dígitos.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).verifyPhoneOtp(
            phone: widget.args.phone,
            token: token,
          );
      if (!mounted) return;
      switch (widget.args.purpose) {
        case OtpPurpose.passwordRecovery:
          context.go(AppRoutes.resetPassword);
        case OtpPurpose.signupVerification:
          context.go(AppRoutes.onboarding);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = _mapAuthError(e.message);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'No se pudo verificar el código. Inténtalo de nuevo.';
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0) return;
    setState(() => _errorMessage = null);
    try {
      await ref.read(authRepositoryProvider).resendPhoneOtp(widget.args.phone);
      _startResendCooldown();
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _mapAuthError(e.message));
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage =
            'No se pudo reenviar el código. Inténtalo de nuevo.');
      }
    }
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('expired') || msg.contains('invalid otp') ||
        msg.contains('invalid token')) {
      return 'Código incorrecto o caducado.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Demasiados intentos. Espera unos minutos.';
    }
    return 'No se pudo verificar el código. Inténtalo de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    final title = switch (widget.args.purpose) {
      OtpPurpose.passwordRecovery => 'VERIFICAR CÓDIGO',
      OtpPurpose.signupVerification => 'CONFIRMAR TELÉFONO',
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Header ──
            SizedBox(
              height: topPadding + 72,
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPadding + 16,
                  left: 8,
                  right: AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    const LhotseBackButton.onSurface(),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      title,
                      style: AppTypography.titleUppercaseLg.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Form ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      'Hemos enviado un código de 6 dígitos a '
                      '${_maskPhone(widget.args.phone)}.',
                      style: AppTypography.annotationParagraph.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    LhotseOtpField(
                      controller: _otpController,
                      onCompleted: (_) => _verify(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _secondsRemaining > 0 ? null : _resend,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _secondsRemaining > 0
                                ? 'REENVIAR CÓDIGO EN ${_secondsRemaining}S'
                                : 'REENVIAR CÓDIGO',
                            style: AppTypography.wordmarkByline.copyWith(
                              color: _secondsRemaining > 0
                                  ? AppColors.accentMuted
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: AppTypography.annotation.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    LhotseSubmitButton(
                      label: 'VERIFICAR',
                      isLoading: _isVerifying,
                      onTap: _verify,
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            SizedBox(height: bottomPadding + AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Mask all but the last two digits: "+34600123456" → "+34 *** *** *56"
  String _maskPhone(String phone) {
    if (phone.length < 4) return phone;
    final tail = phone.substring(phone.length - 2);
    return '${phone.substring(0, 3)} *** *** *$tail';
  }
}
