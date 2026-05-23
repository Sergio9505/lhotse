import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/data/supabase_provider.dart';
import 'consent_provider.dart';

/// Centralised post-auth routing decision. Every entry point that has
/// just authenticated the user (splash for an existing session, login,
/// complete-phone, OTP verify) calls this helper instead of going
/// directly to `/home` or `/onboarding`. It decides:
///
///   1. If `latest_user_consents.terms_accepted` or `privacy_accepted`
///      are false → `/accept-consent` (gate fires regardless of
///      onboarding state).
///   2. If consents OK but `user_onboarding.completed_at` is null →
///      `/onboarding`.
///   3. Otherwise → `/home`.
///
/// Errors during the consent lookup fall back to gating (`/accept-consent`)
/// so a flaky network doesn't let users into the app without consent.
Future<void> routeAfterAuth(WidgetRef ref, BuildContext context) async {
  ref.invalidate(currentUserConsentsProvider);

  late final LatestConsents consents;
  try {
    consents = await ref.read(currentUserConsentsProvider.future);
  } catch (_) {
    if (!context.mounted) return;
    context.go(AppRoutes.acceptConsent);
    return;
  }
  if (!context.mounted) return;

  final hasConsents = consents.termsAccepted && consents.privacyAccepted;
  if (!hasConsents) {
    context.go(AppRoutes.acceptConsent);
    return;
  }

  // Stream-fast path with synchronous fallback for the post-signin window
  // where currentUserIdProvider has not yet emitted (see consent_provider).
  final userId = ref.read(currentUserIdProvider).valueOrNull ??
      ref.read(supabaseClientProvider).auth.currentSession?.user.id;
  if (userId == null) {
    context.go(AppRoutes.welcome);
    return;
  }

  Map<String, dynamic>? onboardingRow;
  try {
    onboardingRow = await ref
        .read(supabaseClientProvider)
        .from('user_onboarding')
        .select('completed_at')
        .eq('user_id', userId)
        .maybeSingle();
  } catch (_) {
    // If we can't read the row, default to taking the user to
    // onboarding — re-asking the questions is safer than dropping a
    // never-onboarded user straight into the app shell.
    onboardingRow = null;
  }
  if (!context.mounted) return;

  if (onboardingRow?['completed_at'] != null) {
    context.go(AppRoutes.home);
  } else {
    context.go(AppRoutes.onboarding);
  }
}
