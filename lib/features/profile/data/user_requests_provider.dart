import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_provider.dart';

/// Type of user-initiated request stored in `public.user_requests`. The
/// allowed values are governed here AND mirrored by the DB CHECK constraint
/// `user_requests_type_check`. Adding a new type = add a value here + add
/// it to the CHECK + wire a new call-site.
enum UserRequestType { vipAccess, investInfo, projectInfo }

extension UserRequestTypeX on UserRequestType {
  /// String stored in `user_requests.type`. Stable wire format.
  String get apiValue => switch (this) {
        UserRequestType.vipAccess => 'vip_access',
        UserRequestType.investInfo => 'invest_info',
        UserRequestType.projectInfo => 'project_info',
      };
}

/// Whether the current user has an **active** request of [type] — i.e. one
/// in `pending` or `completed`. `declined` rows are treated as inexistent
/// so the operator can reopen the CTA by declining; the user can then
/// submit again (a fresh row is inserted, the declined one stays as
/// history for audit). The CTA UI switches to its "EN ESTUDIO" disabled
/// state when this returns true.
///
/// Use this only for global types (`vipAccess`, `investInfo`). For
/// per-project requests use [userProjectRequestExistsProvider].
final userRequestExistsProvider = FutureProvider.family
    .autoDispose<bool, UserRequestType>((ref, type) async {
  assert(type != UserRequestType.projectInfo,
      'Use userProjectRequestExistsProvider(projectId) for project_info');
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return false;
  final row = await ref
      .watch(supabaseClientProvider)
      .from('user_requests')
      .select('id')
      .eq('user_id', userId)
      .eq('type', type.apiValue)
      .neq('status', 'declined')
      .maybeSingle();
  return row != null;
});

/// Per-project active-request existence check for `type='project_info'`.
/// Family key is the project UUID. Returns true while a pending/completed
/// row exists for the (user, project) pair; `declined` rows do not block
/// — the user can re-submit after a decline (a fresh row is inserted and
/// the declined one stays as audit history).
final userProjectRequestExistsProvider = FutureProvider.family
    .autoDispose<bool, String>((ref, projectId) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return false;
  final row = await ref
      .watch(supabaseClientProvider)
      .from('user_requests')
      .select('id')
      .eq('user_id', userId)
      .eq('type', UserRequestType.projectInfo.apiValue)
      .eq('project_id', projectId)
      .neq('status', 'declined')
      .maybeSingle();
  return row != null;
});

/// Submits a request. Uniqueness is partial: only active rows (`pending` or
/// `completed`) collide. If an active row already exists for the
/// `(user, type, project_id)` triple the partial UNIQUE index rejects with
/// code `23505` — swallowed; the existence provider re-fetches and the UI
/// remains locked. If only a `declined` row exists (or no row at all), the
/// INSERT succeeds and a fresh `pending` row is created — past declines
/// stay as history. Any other error re-throws to the caller for UI
/// handling.
///
/// For [UserRequestType.projectInfo], `projectId` is required and the
/// matching existence family provider is invalidated. For the other types
/// `projectId` must be null and [userRequestExistsProvider] is invalidated.
Future<void> submitUserRequest(
  WidgetRef ref,
  UserRequestType type, {
  String? projectId,
}) async {
  assert(
    (type == UserRequestType.projectInfo) == (projectId != null),
    'projectId is required iff type == projectInfo',
  );
  final userId = ref.read(currentUserIdProvider).valueOrNull;
  if (userId == null) return;
  try {
    await ref.read(supabaseClientProvider).from('user_requests').insert({
      'user_id': userId,
      'type': type.apiValue,
      'project_id': ?projectId,
    });
  } on PostgrestException catch (e) {
    if (e.code != '23505') rethrow;
  }
  if (type == UserRequestType.projectInfo) {
    ref.invalidate(userProjectRequestExistsProvider(projectId!));
  } else {
    ref.invalidate(userRequestExistsProvider(type));
  }
}
