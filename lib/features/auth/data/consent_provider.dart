import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/supabase_provider.dart';

/// Current consent state for the signed-in user — derived from
/// `latest_user_consents` view.
///
/// Used **only** by the marketing toggle in `notifications_screen` (and any
/// future profile-level consent UI). Routing/gating decisions live in
/// `BootStateNotifier` (`lib/core/boot/boot_state.dart`), which queries the
/// same view for its own purposes but with `ref.read` semantics — this
/// provider is for **rendering** the current marketing flag, not for
/// driving navigation.
class LatestConsents {
  const LatestConsents({
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.marketingAccepted,
    this.termsAcceptedAt,
    this.privacyAcceptedAt,
    this.marketingAcceptedAt,
  });

  factory LatestConsents.none() => const LatestConsents(
        termsAccepted: false,
        privacyAccepted: false,
        marketingAccepted: false,
      );

  factory LatestConsents.fromJson(Map<String, dynamic> json) {
    return LatestConsents(
      termsAccepted: json['terms_accepted'] as bool? ?? false,
      privacyAccepted: json['privacy_accepted'] as bool? ?? false,
      marketingAccepted: json['marketing_accepted'] as bool? ?? false,
      termsAcceptedAt: _parseDate(json['terms_accepted_at']),
      privacyAcceptedAt: _parseDate(json['privacy_accepted_at']),
      marketingAcceptedAt: _parseDate(json['marketing_accepted_at']),
    );
  }

  final bool termsAccepted;
  final bool privacyAccepted;
  final bool marketingAccepted;
  final DateTime? termsAcceptedAt;
  final DateTime? privacyAcceptedAt;
  final DateTime? marketingAcceptedAt;

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }
}

/// Reads consent state synchronously from `currentSession` (no `ref.watch`
/// on a StreamProvider — that would cause mid-build rebuilds when the
/// stream emits its initial event, orphaning the future. See git history
/// for the diagnosed Riverpod stale-build bug).
///
/// NOT autoDispose: callers (`notifications_screen`) `ref.invalidate` +
/// `ref.watch` after writes; autoDispose would cause mid-await disposal
/// when no listener is active.
final currentUserConsentsProvider =
    FutureProvider<LatestConsents>((ref) async {
  final userId =
      ref.read(supabaseClientProvider).auth.currentSession?.user.id;
  if (userId == null) return LatestConsents.none();

  final data = await ref
      .read(supabaseClientProvider)
      .from('latest_user_consents')
      .select()
      .eq('user_id', userId)
      .maybeSingle()
      .timeout(const Duration(seconds: 8));

  return data != null ? LatestConsents.fromJson(data) : LatestConsents.none();
});
