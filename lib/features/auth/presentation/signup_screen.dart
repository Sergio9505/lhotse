import 'package:flutter/gestures.dart';
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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Completa todos los campos.');
      return;
    }
    if (!_isEmail(email)) {
      setState(() => _errorMessage = 'Introduce un email válido.');
      return;
    }
    if (password.length < 8) {
      setState(
        () => _errorMessage = 'La contraseña debe tener al menos 8 caracteres.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      // If email confirmation is disabled, signUp returns a session directly.
      // If enabled, session is null; fall back to signIn (email confirmation
      // is deferred per current product decision).
      if (response.session == null) {
        await repo.signIn(email: email, password: password);
      }
      if (!mounted) return;
      context.go(AppRoutes.onboarding);
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
          _errorMessage = 'Error al crear la cuenta. Inténtalo de nuevo.';
        });
      }
    }
  }

  bool _isEmail(String value) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(value);
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('user already') ||
        msg.contains('already exists')) {
      return 'Ya existe una cuenta con este email. Inicia sesión.';
    }
    if (msg.contains('password') && msg.contains('weak')) {
      return 'La contraseña es demasiado débil.';
    }
    if (msg.contains('invalid email')) {
      return 'Introduce un email válido.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Demasiados intentos. Espera unos minutos.';
    }
    return 'Error al crear la cuenta. Inténtalo de nuevo.';
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
                      'CREAR CUENTA',
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
                      label: 'Nombre completo',
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    LhotseAuthField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    LhotseAuthField(
                      label: 'Contraseña',
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _signUp(),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Mínimo 8 caracteres.',
                      style: AppTypography.annotation.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Legal disclaimer — opens existing legal screens
                    _LegalDisclaimer(
                      onTermsTap: () => context.push(AppRoutes.profileTerms),
                      onPrivacyTap: () =>
                          context.push(AppRoutes.profilePrivacy),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: AppTypography.annotation.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    _SubmitButton(
                      label: 'CREAR CUENTA',
                      isLoading: _isLoading,
                      onTap: _signUp,
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

// ── Legal disclaimer ─────────────────────────────────────────────────────────

class _LegalDisclaimer extends StatelessWidget {
  const _LegalDisclaimer({
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    final body = AppTypography.annotationParagraph.copyWith(
      color: AppColors.accentMuted,
    );
    final link = body.copyWith(
      color: AppColors.textPrimary,
      decoration: TextDecoration.underline,
      decorationThickness: 0.5,
    );

    return RichText(
      text: TextSpan(
        style: body,
        children: [
          const TextSpan(text: 'Al crear una cuenta aceptas los '),
          TextSpan(
            text: 'Términos',
            style: link,
            recognizer: _Tap(onTermsTap),
          ),
          const TextSpan(text: ' y la '),
          TextSpan(
            text: 'Política de Privacidad',
            style: link,
            recognizer: _Tap(onPrivacyTap),
          ),
          const TextSpan(text: ' de Lhotse Group.'),
        ],
      ),
    );
  }
}

// Lightweight TapGestureRecognizer wrapper kept inline to avoid an extra
// import surface in the screen file.
class _Tap extends TapGestureRecognizer {
  _Tap(VoidCallback onTap) {
    this.onTap = onTap;
  }
}

// ── Submit button (mirrors LoginScreen for visual coherence) ──────────────────

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:
          widget.isLoading ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.6 : 1.0,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          color: AppColors.primary,
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.label,
                  style: AppTypography.labelUppercaseMd.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }
}
