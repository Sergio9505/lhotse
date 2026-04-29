import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/onboarding_questions.dart';
import 'onboarding_repository.dart';
import 'onboarding_state.dart';

final onboardingControllerProvider =
    StateNotifierProvider.autoDispose<OnboardingController, OnboardingState>(
  (ref) => OnboardingController(ref),
);

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref) : super(const OnboardingState());

  final Ref _ref;

  OnboardingRepository get _repo => _ref.read(onboardingRepositoryProvider);

  bool get canContinue {
    if (state.isSaving) return false;
    return _isValid();
  }

  /// Selects or deselects an option value for the current step.
  /// For single-select: replaces the current answer.
  /// For multi-select: toggles membership, respecting maxSelections cap.
  void select(String value) {
    final q = kOnboardingQuestions[state.stepIndex];
    final updated = Map<int, Object>.from(state.answers);

    if (q.type == QuestionType.single) {
      updated[state.stepIndex] = value;
    } else {
      final current =
          (state.answers[state.stepIndex] as List<String>?) ?? <String>[];
      List<String> next;
      if (current.contains(value)) {
        next = current.where((v) => v != value).toList();
      } else {
        if (q.maxSelections != null && current.length >= q.maxSelections!) {
          return; // cap reached — ignore tap
        }
        next = [...current, value];
      }
      updated[state.stepIndex] = next;
    }

    state = state.copyWith(answers: updated, error: null);
  }

  Future<void> next() async {
    if (!canContinue) return;
    state = state.copyWith(isSaving: true, error: null);
    try {
      final q = kOnboardingQuestions[state.stepIndex];
      final value = state.answers[state.stepIndex];
      await _repo.upsertAnswer(q.column, value);
      if (state.stepIndex == kOnboardingQuestions.length - 1) {
        await _repo.markCompleted();
      }
      state = state.copyWith(
        stepIndex: state.stepIndex + 1,
        isSaving: false,
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'Error al guardar. Inténtalo de nuevo.',
      );
    }
  }

  void previous() {
    if (state.stepIndex > 0) {
      state = state.copyWith(stepIndex: state.stepIndex - 1, error: null);
    }
  }

  bool _isValid() {
    final q = kOnboardingQuestions[state.stepIndex];
    final answer = state.answers[state.stepIndex];
    if (q.type == QuestionType.single) {
      return answer is String && answer.isNotEmpty;
    }
    final list = answer as List<String>?;
    return list != null && list.isNotEmpty;
  }
}
