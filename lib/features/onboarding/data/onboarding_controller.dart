import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/consent_metadata.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/consent_provider.dart';
import '../domain/onboarding_questions.dart';
import 'onboarding_repository.dart';
import 'onboarding_state.dart';

final onboardingControllerProvider =
    StateNotifierProvider.autoDispose<OnboardingController, OnboardingState>(
  (ref) => OnboardingController(ref)..hydrate(),
);

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref) : super(const OnboardingState());

  final Ref _ref;

  OnboardingRepository get _repo => _ref.read(onboardingRepositoryProvider);

  /// Read `latest_user_consents` once at construction so the host can
  /// skip the consent gate for signup-public users who already have
  /// rows in `consent_log`. Admin-created users land with empty log →
  /// gate shows. Errors are swallowed: if the fetch fails we default to
  /// showing the gate (safer than letting the user proceed without
  /// consent on a flaky network).
  Future<void> hydrate() async {
    try {
      final consents =
          await _ref.read(currentUserConsentsProvider.future);
      if (!mounted) return;
      if (consents.termsAccepted && consents.privacyAccepted) {
        state = state.copyWith(consentAccepted: true);
      }
    } catch (_) {
      // Default state (consentAccepted=false) leaves the gate up.
    }
  }

  /// Called from the in-onboarding consent step. Writes three rows in
  /// consent_log (TC granted, Privacy granted, Marketing per checkbox)
  /// via the `record_consent` RPC, then advances past the gate. The
  /// `currentUserConsentsProvider` is invalidated so any other consumer
  /// (e.g. edit profile) sees the new state.
  Future<void> acceptConsents(bool marketingConsent) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final meta = await collectConsentMetadata();
      final repo = _ref.read(authRepositoryProvider);
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
          granted: marketingConsent,
          meta: meta,
        ),
      ]);
      _ref.invalidate(currentUserConsentsProvider);
      if (!mounted) return;
      state = state.copyWith(consentAccepted: true, isSaving: false);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        error: 'No se pudieron guardar los consentimientos. Inténtalo de nuevo.',
      );
    }
  }

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
