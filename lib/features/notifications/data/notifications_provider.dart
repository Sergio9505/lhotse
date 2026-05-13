import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/supabase_provider.dart';
import '../../../core/domain/app_notification.dart';

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .eq('delivered_in_app', true)
      .order('created_at', ascending: false);
  return (data as List<dynamic>)
      .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
      .toList();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return 0;
  final data = await ref
      .watch(supabaseClientProvider)
      .from('unread_notification_counts')
      .select()
      .eq('user_id', userId)
      .maybeSingle();
  return (data?['unread_count'] as num?)?.toInt() ?? 0;
});

/// Marks all in-app notifications as read for the current user.
/// The RPC signature is `mark_notifications_read(notification_ids uuid[])`
/// and filters internally by `auth.uid()`, so we collect the unread ids
/// from the already-loaded provider state.
Future<void> markNotificationsRead(WidgetRef ref) async {
  final list = ref.read(notificationsProvider).valueOrNull ?? const [];
  final unreadIds = [
    for (final n in list)
      if (!n.isRead) n.id,
  ];
  if (unreadIds.isEmpty) return;
  await ref
      .read(supabaseClientProvider)
      .rpc('mark_notifications_read', params: {'notification_ids': unreadIds});
  ref.invalidate(notificationsProvider);
  ref.invalidate(unreadNotificationCountProvider);
}
