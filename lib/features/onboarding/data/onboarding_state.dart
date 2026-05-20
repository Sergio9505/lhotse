import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    /// Whether the user has already accepted Terms + Privacy. The
    /// onboarding host renders a consent gate before the first question
    /// when this is false. Initialised from `latest_user_consents` on
    /// controller construction so signup-public users (who consented
    /// during the signup checkbox flow) skip the gate.
    @Default(false) bool consentAccepted,
    @Default(0) int stepIndex,
    @Default({}) Map<int, Object> answers,
    @Default(false) bool isSaving,
    String? error,
  }) = _OnboardingState;
}
