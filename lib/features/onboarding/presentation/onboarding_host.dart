import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_mark.dart';
import '../data/onboarding_controller.dart';
import '../domain/onboarding_questions.dart';
import 'widgets/onboarding_question_view.dart';

class OnboardingHost extends ConsumerWidget {
  const OnboardingHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;

    // Navigate to done screen once all questions are answered.
    ref.listen(
      onboardingControllerProvider.select((s) => s.stepIndex),
      (prev, next) {
        if (next >= kOnboardingQuestions.length && context.mounted) {
          context.go(AppRoutes.onboardingDone);
        }
      },
    );

    final state = ref.watch(onboardingControllerProvider);
    final isFirstStep = state.stepIndex == 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Chrome ──────────────────────────────────────────────────────
            SizedBox(
              height: topPadding + 64,
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPadding + 16,
                  left: isFirstStep ? AppSpacing.lg : 8,
                  right: AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    if (isFirstStep)
                      const LhotseMark(color: AppColors.textPrimary)
                    else
                      LhotseBackButton.onSurface(
                        onTap: () => ref
                            .read(onboardingControllerProvider.notifier)
                            .previous(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Question — fades between steps ──────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                  child: child,
                ),
                child: OnboardingQuestionView(
                  key: ValueKey(state.stepIndex),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
