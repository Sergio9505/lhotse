import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../data/auth_repository.dart';
import 'widgets/lhotse_auth_field.dart';
import 'widgets/lhotse_submit_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Completa todos los campos');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
      // Router redirect handles navigation automatically
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
          _errorMessage = 'Error al iniciar sesión. Inténtalo de nuevo.';
        });
      }
    }
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials') ||
        msg.contains('email not confirmed')) {
      return 'Credenciales incorrectas. Verifica tu email y contraseña.';
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Demasiados intentos. Espera unos minutos.';
    }
    return 'Error al iniciar sesión. Inténtalo de nuevo.';
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
                    'INICIAR SESIÓN',
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

                  LhotseAuthField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  LhotseAuthField(
                    label: 'Contraseña',
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signIn(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push(AppRoutes.forgotPassword),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'OLVIDÉ MI CONTRASEÑA',
                          style: AppTypography.wordmarkByline.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Error banner
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: AppTypography.annotation.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Submit button
                  LhotseSubmitButton(
                    label: 'ENTRAR',
                    isLoading: _isLoading,
                    onTap: _signIn,
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
