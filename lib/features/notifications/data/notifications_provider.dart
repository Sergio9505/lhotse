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

/// Marks all notifications as read for the current user via RPC.
Future<void> markNotificationsRead(WidgetRef ref) async {
  final userId = ref.read(currentUserIdProvider).valueOrNull;
  if (userId == null) return;
  await ref
      .read(supabaseClientProvider)
      .rpc('mark_notifications_read', params: {'p_user_id': userId});
  ref.invalidate(notificationsProvider);
  ref.invalidate(unreadNotificationCountProvider);
}
