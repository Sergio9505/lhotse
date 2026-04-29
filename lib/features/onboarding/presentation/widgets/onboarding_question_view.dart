import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/onboarding_controller.dart';
import '../../data/onboarding_state.dart';
import '../../domain/onboarding_questions.dart';
import 'option_row.dart';

class OnboardingQuestionView extends ConsumerWidget {
  const OnboardingQuestionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final q = kOnboardingQuestions[state.stepIndex];
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final stepLabel =
        '${(state.stepIndex + 1).toString().padLeft(2, '0')} / ${kOnboardingQuestions.length.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Step indicator ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            stepLabel,
            style: AppTypography.labelUppercaseSm.copyWith(
              color: AppColors.accentMuted,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Question ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            q.question,
            style: AppTypography.editorialTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),

        if (q.helper != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              q.helper!,
              style: AppTypography.annotationParagraph.copyWith(
                color: AppColors.accentMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // ── Options ─────────────────────────────────────────────────────────
        _OptionList(q: q, state: state, controller: controller),

        const SizedBox(height: AppSpacing.lg),

        // ── Error ────────────────────────────────────────────────────────────
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              state.error!,
              style: AppTypography.annotation.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),

        const Spacer(),

        // ── CTA ──────────────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            bottomPadding > 0 ? bottomPadding + AppSpacing.md : AppSpacing.lg,
          ),
          child: _ContinueButton(
            isSaving: state.isSaving,
            enabled: controller.canContinue,
            onTap: controller.next,
          ),
        ),
      ],
    );
  }
}

// ── Option list ──────────────────────────────────────────────────────────────

class _OptionList extends StatelessWidget {
  const _OptionList({
    required this.q,
    required this.state,
    required this.controller,
  });

  final OnboardingQuestion q;
  final OnboardingState state;
  final OnboardingController controller;

  bool _isSelected(String value) {
    final answer = state.answers[state.stepIndex];
    if (q.type == QuestionType.single) {
      return answer == value;
    }
    final list = answer as List<String>?;
    return list?.contains(value) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top border
        Divider(height: 1, thickness: 0.5, color: AppColors.border),
        for (final opt in q.options)
          OptionRow(
            label: opt.label,
            selected: _isSelected(opt.value),
            onTap: () => controller.select(opt.value),
          ),
        if (q.type == QuestionType.multi && q.maxSelections != null)
          _SelectionCounter(state: state, q: q),
      ],
    );
  }
}

// ── Selection counter (Q7) ───────────────────────────────────────────────────

class _SelectionCounter extends StatelessWidget {
  const _SelectionCounter({required this.state, required this.q});

  final OnboardingState state;
  final OnboardingQuestion q;

  @override
  Widget build(BuildContext context) {
    final list =
        (state.answers[state.stepIndex] as List<String>?) ?? <String>[];
    final count = list.length;
    final max = q.maxSelections!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Text(
        '$count / $max',
        style: AppTypography.labelUppercaseSm.copyWith(
          color: count == max ? AppColors.textPrimary : AppColors.accentMuted,
        ),
      ),
    );
  }
}

// ── Continue button ──────────────────────────────────────────────────────────

class _ContinueButton extends StatefulWidget {
  const _ContinueButton({
    required this.isSaving,
    required this.enabled,
    required this.onTap,
  });

  final bool isSaving;
  final bool enabled;
  final Future<void> Function() onTap;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:
          widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: !widget.enabled ? 0.35 : _pressed ? 0.6 : 1.0,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          color: AppColors.primary,
          child: widget.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'CONTINUAR',
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
