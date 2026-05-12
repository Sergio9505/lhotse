import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../data/auth_repository.dart';
import 'otp_verify_screen.dart';
import 'widgets/lhotse_auth_field.dart';
import 'widgets/lhotse_submit_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _phoneController.text.trim();
    final phone = _normalizePhone(raw);

    if (phone == null) {
      setState(
        () => _errorMessage = 'Introduce un teléfono válido con prefijo país.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).sendPhoneOtp(phone);
      if (!mounted) return;
      context.push(
        AppRoutes.otpVerify,
        extra: OtpVerifyArgs(
          phone: phone,
          purpose: OtpPurpose.passwordRecovery,
        ),
      );
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _mapAuthError(e.message);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se pudo enviar el código. Inténtalo de nuevo.';
        });
      }
    }
  }

  String? _normalizePhone(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.startsWith('+') &&
        RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(cleaned)) {
      return cleaned;
    }
    // Default to Spain if user typed only digits
    if (RegExp(r'^[1-9]\d{8}$').hasMatch(cleaned)) {
      return '+34$cleaned';
    }
    return null;
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Demasiados intentos. Espera unos minutos.';
    }
    if (msg.contains('invalid phone')) {
      return 'Introduce un teléfono válido.';
    }
    // Avoid leaking whether the phone is registered.
    return 'No se pudo enviar el código. Inténtalo de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

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
                      'RECUPERAR ACCESO',
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
                      'Introduce tu teléfono. Te enviaremos un código por SMS '
                      'para verificar tu identidad y definir una nueva '
                      'contraseña.',
                      style: AppTypography.annotationParagraph.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    LhotseAuthField(
                      label: 'Teléfono',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofocus: true,
                      onSubmitted: (_) => _submit(),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Formato internacional, por ejemplo +34 600 000 000.',
                      style: AppTypography.annotation.copyWith(
                        color: AppColors.accentMuted,
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
                      label: 'ENVIAR CÓDIGO',
                      isLoading: _isLoading,
                      onTap: _submit,
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
}
