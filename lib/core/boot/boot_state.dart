import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_provider.dart';

/// Single source of truth for post-auth routing.
///
/// Eagerly computes the user's required destination by checking, in order:
///
///   1. Is there a session? → [BootSignedOut] if not.
///   2. Phone verified?     → [BootPendingPhone] if not.
///   3. Consents granted?   → [BootPendingConsent] if not.
///   4. Onboarding done?    → [BootPendingOnboarding] if not.
///   5. All good            → [BootReady].
///
/// The router redirect reads the current state synchronously and maps it to
/// the canonical destination route — no async work in the redirect callback.
/// Screens that mutate auth state (login, OTP verify, accept consent submit,
/// onboarding completion) call [BootStateNotifier.refresh] explicitly so the
/// router re-evaluates with the fresh state.
///
/// On network error during the consent / onboarding fetch we **fail closed**:
/// state is set to [BootPendingConsent]. Re-asking for consent is annoying
/// but compliance-safe; letting a user through without verifying consent is
/// not acceptable for an RGPD-grade app.
sealed class BootState {
  const BootState();
}

class BootLoading extends BootState {
  const BootLoading();
}

class BootSignedOut extends BootState {
  const BootSignedOut();
}

class BootPendingPhone extends BootState {
  const BootPendingPhone();
}

class BootPendingConsent extends BootState {
  const BootPendingConsent();
}

class BootPendingOnboarding extends BootState {
  const BootPendingOnboarding();
}

class BootReady extends BootState {
  const BootReady();
}

class BootStateNotifier extends Notifier<BootState> {
  StreamSubscription<AuthState>? _authSub;
  int _refreshSeq = 0;

  @override
  BootState build() {
    final client = ref.watch(supabaseClientProvider);
    _authSub = client.auth.onAuthStateChange.listen((_) => refresh());
    ref.onDispose(() => _authSub?.cancel());
    // Kick off the initial computation on the next microtask so the build
    // returns synchronously with BootLoading. Real value lands shortly after.
    Future.microtask(refresh);
    return const BootLoading();
  }

  /// Recomputes the user's required destination. Safe to call multiple times
  /// concurrently — only the latest invocation's result is committed (see
  /// `_refreshSeq` guard).
  Future<void> refresh() async {
    final seq = ++_refreshSeq;
    final client = ref.read(supabaseClientProvider);
    final session = client.auth.currentSession;

    if (session == null) {
      _commit(seq, const BootSignedOut());
      return;
    }
    if (session.user.phoneConfirmedAt == null) {
      _commit(seq, const BootPendingPhone());
      return;
    }

    // Don't transition through BootLoading mid-refresh — the router would
    // bounce the user to /splash and the splash widget would replay its
    // intro video on every refresh (post accept-consent, post-onboarding,
    // post-login). The previous state stays committed until the async
    // query resolves; the final commit at the end of `try` flips to the
    // correct state. BootLoading is reserved exclusively for the very
    // first build() of this Notifier on cold start.
    final userId = session.user.id;

    try {
      final consents = await client
          .from('latest_user_consents')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));
      if (seq != _refreshSeq) return;

      final termsOk = consents?['terms_accepted'] == true;
      final privacyOk = consents?['privacy_accepted'] == true;
      if (!termsOk || !privacyOk) {
        _commit(seq, const BootPendingConsent());
        return;
      }

      final onboarding = await client
          .from('user_onboarding')
          .select('completed_at')
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));
      if (seq != _refreshSeq) return;

      if (onboarding?['completed_at'] == null) {
        _commit(seq, const BootPendingOnboarding());
        return;
      }

      _commit(seq, const BootReady());
    } on TimeoutException catch (e) {
      debugPrint('[BootState] timeout during refresh: $e — fail-closed to consent gate');
      _commit(seq, const BootPendingConsent());
    } catch (e) {
      debugPrint('[BootState] error during refresh: $e — fail-closed to consent gate');
      _commit(seq, const BootPendingConsent());
    }
  }

  void _commit(int seq, BootState next) {
    if (seq != _refreshSeq) return;
    state = next;
  }
}

final bootStateProvider =
    NotifierProvider<BootStateNotifier, BootState>(BootStateNotifier.new);
