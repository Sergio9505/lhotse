import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/supabase_provider.dart';

/// Current consent state for the signed-in user — derived from
/// `latest_user_consents` view (pivot of the consent_log audit table).
/// Used by `edit_profile_screen` to seed the marketing toggle.
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

final currentUserConsentsProvider =
    FutureProvider.autoDispose<LatestConsents>((ref) async {
  // Watch the auth-state stream so the provider invalidates on
  // login/logout — matches the per-user provider pattern used elsewhere
  // (see CLAUDE.md gotcha).
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return LatestConsents.none();

  final data = await ref
      .watch(supabaseClientProvider)
      .from('latest_user_consents')
      .select()
      .eq('user_id', userId)
      .maybeSingle();

  return data != null ? LatestConsents.fromJson(data) : LatestConsents.none();
});
