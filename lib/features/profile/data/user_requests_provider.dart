import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_provider.dart';

/// Type of user-initiated request stored in `public.user_requests`. The
/// allowed values are governed here (single gatekeeper, since only the
/// user-facing app inserts into the table via RLS). Adding a new type =
/// add a value here + wire a new call-site; no DB migration required.
enum UserRequestType { vipAccess, investInfo }

extension UserRequestTypeX on UserRequestType {
  /// String stored in `user_requests.type`. Stable wire format.
  String get apiValue => switch (this) {
        UserRequestType.vipAccess => 'vip_access',
        UserRequestType.investInfo => 'invest_info',
      };
}

/// Whether the current user has ever submitted a request of [type].
/// The CTA UI switches to its "EN ESTUDIO" disabled state once true.
/// Status (pending / completed / declined) is intentionally ignored —
/// from the user's point of view, the request stays under review
/// regardless of internal operator workflow.
final userRequestExistsProvider = FutureProvider.family
    .autoDispose<bool, UserRequestType>((ref, type) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return false;
  final row = await ref
      .watch(supabaseClientProvider)
      .from('user_requests')
      .select('id')
      .eq('user_id', userId)
      .eq('type', type.apiValue)
      .maybeSingle();
  return row != null;
});

/// Submits a request. If one already exists for (user, type) the UNIQUE
/// constraint rejects with code `23505` — swallowed; the existence
/// provider re-fetches and the UI remains locked. Any other error
/// re-throws to the caller for UI handling.
Future<void> submitUserRequest(WidgetRef ref, UserRequestType type) async {
  final userId = ref.read(currentUserIdProvider).valueOrNull;
  if (userId == null) return;
  try {
    await ref.read(supabaseClientProvider).from('user_requests').insert({
      'user_id': userId,
      'type': type.apiValue,
    });
  } on PostgrestException catch (e) {
    if (e.code != '23505') rethrow;
  }
  ref.invalidate(userRequestExistsProvider(type));
}
