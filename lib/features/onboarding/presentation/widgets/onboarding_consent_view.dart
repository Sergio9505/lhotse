import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/consent_checkboxes.dart';
import '../../../auth/presentation/widgets/lhotse_submit_button.dart';
import '../../data/onboarding_controller.dart';

/// First step of the onboarding flow — shown only when the controller's
/// `consentAccepted == false` (i.e., the user has no Terms + Privacy
/// rows in `consent_log`). Admin-created users land here; signup-public
/// users skip straight to the first question because the trigger
/// already wrote their consents on `auth.users` insert.
///
/// Layout mirrors `OnboardingQuestionView` (same paddings + tipografía
/// editorial) so the cross-fade between consent and the first question
/// reads as a single, continuous flow.
class OnboardingConsentView extends ConsumerStatefulWidget {
  const OnboardingConsentView({super.key});

  @override
  ConsumerState<OnboardingConsentView> createState() =>
      _OnboardingConsentViewState();
}

class _OnboardingConsentViewState extends ConsumerState<OnboardingConsentView> {
  bool _legalAccepted = false;
  bool _marketingConsent = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
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
            'Necesitamos que aceptes los términos para acceder a tu cuenta.',
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
        if (state.error != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              state.error!,
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
            bottomPadding > 0 ? bottomPadding + AppSpacing.md : AppSpacing.lg,
          ),
          child: LhotseSubmitButton(
            label: 'CONTINUAR',
            isLoading: state.isSaving,
            enabled: _legalAccepted && !state.isSaving,
            onTap: () => controller.acceptConsents(_marketingConsent),
          ),
        ),
      ],
    );
  }
}
