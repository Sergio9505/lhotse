import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import 'widgets/lhotse_auth_field.dart';
import 'widgets/lhotse_submit_button.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Completa ambos campos.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage =
          'La contraseña debe tener al menos 8 caracteres.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updatePassword(password);
      await repo.signOut();
      if (!mounted) return;
      // Router redirect will move to /welcome when session clears.
      // Land on /login so the user can sign in immediately.
      context.go(AppRoutes.login);
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
          _errorMessage =
              'No se pudo actualizar la contraseña. Inténtalo de nuevo.';
        });
      }
    }
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('weak') || msg.contains('short')) {
      return 'La contraseña es demasiado débil.';
    }
    if (msg.contains('same') || msg.contains('different')) {
      return 'La nueva contraseña debe ser distinta a la anterior.';
    }
    return 'No se pudo actualizar la contraseña. Inténtalo de nuevo.';
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
            // ── Header (no back button — flow is forward-only after OTP) ──
            SizedBox(
              height: topPadding + 72,
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPadding + 16,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'NUEVA CONTRASEÑA',
                    style: AppTypography.titleUppercaseLg.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
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
                      'Define una nueva contraseña para tu cuenta.',
                      style: AppTypography.annotationParagraph.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    LhotseAuthField(
                      label: 'Nueva contraseña',
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Mínimo 8 caracteres.',
                      style: AppTypography.annotation.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    LhotseAuthField(
                      label: 'Confirmar contraseña',
                      controller: _confirmController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
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
                      label: 'GUARDAR',
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
