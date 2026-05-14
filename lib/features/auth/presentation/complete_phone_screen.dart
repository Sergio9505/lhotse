import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import 'otp_verify_screen.dart';
import 'widgets/lhotse_phone_field.dart';
import 'widgets/lhotse_submit_button.dart';

/// Phone capture for users who land with a valid session but
/// `auth.users.phone_confirmedAt == null` — typically created via the
/// Supabase admin or aborted a pre-feature signup. Mirrors the signup phone
/// step (LhotsePhoneField → attachPhone → OtpVerifyScreen) but without the
/// email + password fields, since the session already exists.
///
/// Replaces the historical dead-end that signed those users out asking them
/// to "register again".
class CompletePhoneScreen extends ConsumerStatefulWidget {
  const CompletePhoneScreen({super.key});

  @override
  ConsumerState<CompletePhoneScreen> createState() =>
      _CompletePhoneScreenState();
}

class _CompletePhoneScreenState extends ConsumerState<CompletePhoneScreen> {
  final _phoneController = LhotsePhoneController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final phone = _phoneController.e164;
    if (phone == null || _phoneController.localNumber.isEmpty) {
      setState(() => _errorMessage = 'Introduce un teléfono válido.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.attachPhone(phone);
      if (!mounted) return;

      context.go(
        AppRoutes.otpVerify,
        extra: OtpVerifyArgs(
          phone: phone,
          purpose: OtpPurpose.signupVerification,
        ),
      );
    } on AuthException catch (e) {
      assert(() {
        debugPrint(
          '[CompletePhone] attachPhone AuthException: '
          'code=${e.statusCode} msg="${e.message}"',
        );
        return true;
      }());
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
          _errorMessage = 'No se pudo enviar el SMS. Inténtalo de nuevo.';
        });
      }
    }
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('phone') && msg.contains('invalid')) {
      return 'Introduce un teléfono válido.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Demasiados intentos. Espera unos minutos.';
    }
    // Phone collision — covers the Supabase variants seen in practice:
    // "User with this phone has already been registered", "A user with this
    // phone number already exists", "Phone number is already in use",
    // "Duplicate phone".
    final phoneAlreadyTaken = msg.contains('already registered') ||
        (msg.contains('user') && msg.contains('already')) ||
        (msg.contains('phone') &&
            (msg.contains('exists') ||
                msg.contains('taken') ||
                msg.contains('in use') ||
                msg.contains('duplicate')));
    if (phoneAlreadyTaken) {
      return 'Ese teléfono ya está vinculado a otra cuenta.';
    }
    if (msg.contains('sms') &&
        (msg.contains('provider') || msg.contains('disabled'))) {
      return 'No se puede enviar el SMS. Inténtalo más tarde.';
    }
    return 'No se pudo enviar el SMS. Inténtalo de nuevo.';
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    context.go(AppRoutes.welcome);
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
            SizedBox(
              height: topPadding + 72,
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPadding + 16,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    Text(
                      'VERIFICA TU TELÉFONO',
                      style: AppTypography.titleUppercaseLg.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Para completar tu cuenta necesitamos un número móvil. '
                      'Te enviaremos un código por SMS para confirmar que es tuyo.',
                      style: AppTypography.bodyReading.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    LhotsePhoneField(
                      controller: _phoneController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _send(),
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
                      onTap: _send,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _isLoading ? null : _signOut,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'CERRAR SESIÓN',
                            style: AppTypography.wordmarkByline.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
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
