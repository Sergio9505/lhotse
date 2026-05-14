import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/supabase_provider.dart';

class NotificationPreferences {
  /// Defaults aligned with the DB column defaults on
  /// `notification_preferences` so the local fallback (when no row exists
  /// yet) matches what users would see once upsert creates their row.
  const NotificationPreferences({
    this.investmentUpdates = true,
    this.documents = true,
    this.groupNews = true,
    this.events = true,
    this.pushEnabled = true,
    this.emailEnabled = false,
  });

  final bool investmentUpdates;
  final bool documents;
  final bool groupNews;
  final bool events;
  final bool pushEnabled;
  final bool emailEnabled;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        investmentUpdates: json['investment_updates'] as bool? ?? true,
        documents: json['documents'] as bool? ?? true,
        groupNews: json['group_news'] as bool? ?? true,
        events: json['events'] as bool? ?? true,
        pushEnabled: json['push_enabled'] as bool? ?? true,
        emailEnabled: json['email_enabled'] as bool? ?? false,
      );

  NotificationPreferences copyWith({
    bool? investmentUpdates,
    bool? documents,
    bool? groupNews,
    bool? events,
    bool? pushEnabled,
    bool? emailEnabled,
  }) =>
      NotificationPreferences(
        investmentUpdates: investmentUpdates ?? this.investmentUpdates,
        documents: documents ?? this.documents,
        groupNews: groupNews ?? this.groupNews,
        events: events ?? this.events,
        pushEnabled: pushEnabled ?? this.pushEnabled,
        emailEnabled: emailEnabled ?? this.emailEnabled,
      );

  Map<String, dynamic> toUpdateMap() => {
        'investment_updates': investmentUpdates,
        'documents': documents,
        'group_news': groupNews,
        'events': events,
        'push_enabled': pushEnabled,
        'email_enabled': emailEnabled,
      };
}

final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences?>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return null;
  final data = await ref
      .watch(supabaseClientProvider)
      .from('notification_preferences')
      .select()
      .eq('user_id', userId)
      .maybeSingle();
  return data != null
      ? NotificationPreferences.fromJson(data)
      : null;
});

/// Upserts the user's notification preferences. `update` alone is a no-op
/// when the user has no row yet (admin-created / pre-feature users), so a
/// silent-fail toggle would have looked like it worked client-side but
/// never persisted. `upsert` with `onConflict: 'user_id'` inserts on first
/// toggle and updates from then on.
Future<void> updateNotificationPreferences(
    WidgetRef ref, NotificationPreferences prefs) async {
  final userId = ref.read(currentUserIdProvider).valueOrNull;
  if (userId == null) return;
  await ref
      .read(supabaseClientProvider)
      .from('notification_preferences')
      .upsert({
    'user_id': userId,
    ...prefs.toUpdateMap(),
  }, onConflict: 'user_id');
  ref.invalidate(notificationPreferencesProvider);
}
