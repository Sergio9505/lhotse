import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/boot/boot_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/consent_metadata.dart';
import '../../../core/widgets/lhotse_mark.dart';
import '../data/auth_repository.dart';
import 'widgets/consent_checkboxes.dart';
import 'widgets/lhotse_submit_button.dart';

/// Gate that fires when the router sees `BootPendingConsent`. Renders the
/// same two consent checkboxes the public signup uses, but on its own
/// dedicated route. Back gesture is disabled — the only way past this
/// screen is to tilde the legal checkbox and tap CONTINUAR, which writes
/// three rows to `consent_log` via the RPC and then refreshes the boot
/// state machine; the router then redirects to /onboarding or /home.
class AcceptConsentScreen extends ConsumerStatefulWidget {
  const AcceptConsentScreen({super.key});

  @override
  ConsumerState<AcceptConsentScreen> createState() =>
      _AcceptConsentScreenState();
}

class _AcceptConsentScreenState extends ConsumerState<AcceptConsentScreen> {
  bool _legalAccepted = false;
  bool _marketingConsent = false;
  bool _saving = false;
  String? _error;

  Future<void> _accept() async {
    if (_saving || !_legalAccepted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final meta = await collectConsentMetadata();
      final repo = ref.read(authRepositoryProvider);
      await Future.wait([
        repo.recordConsent(
          consentType: 'terms_and_conditions',
          granted: true,
          documentVersion:
              'https://lhotsegroup.com/es/terminos-y-condiciones-aplicacion-movil/',
          meta: meta,
        ),
        repo.recordConsent(
          consentType: 'privacy_policy',
          granted: true,
          documentVersion: 'https://lhotsegroup.com/en/privacy-policy/',
          meta: meta,
        ),
        repo.recordConsent(
          consentType: 'marketing',
          granted: _marketingConsent,
          meta: meta,
        ),
      ]);
      if (!mounted) return;
      await ref.read(bootStateProvider.notifier).refresh();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'No se pudieron guardar los consentimientos. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false, // gate obligatorio — sin escape via back gesture
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: topPadding + 64,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topPadding + 16,
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                  ),
                  child: const Row(
                    children: [LhotseMark(color: AppColors.textPrimary)],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Antes de continuar',
                  style: AppTypography.editorialTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Necesitamos que aceptes los términos para acceder a tu '
                  'cuenta.',
                  style: AppTypography.annotationParagraph.copyWith(
                    color: AppColors.accentMuted,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: LegalConsentCheckbox(
                  value: _legalAccepted,
                  onChanged: (v) => setState(() => _legalAccepted = v),
                  onTermsTap: () => context.push(AppRoutes.profileTerms),
                  onPrivacyTap: () => context.push(AppRoutes.profilePrivacy),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: MarketingConsentCheckbox(
                  value: _marketingConsent,
                  onChanged: (v) => setState(() => _marketingConsent = v),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(
                    _error!,
                    style: AppTypography.annotation.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  bottomPadding > 0
                      ? bottomPadding + AppSpacing.md
                      : AppSpacing.lg,
                ),
                child: LhotseSubmitButton(
                  label: 'CONTINUAR',
                  isLoading: _saving,
                  enabled: _legalAccepted && !_saving,
                  onTap: _accept,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
