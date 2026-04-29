import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int stepIndex,
    @Default({}) Map<int, Object> answers,
    @Default(false) bool isSaving,
    String? error,
  }) = _OnboardingState;
}
