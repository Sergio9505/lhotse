import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/supabase_provider.dart';

class NotificationPreferences {
  const NotificationPreferences({
    this.investmentUpdates = true,
    this.newOpportunities = true,
    this.documents = false,
    this.groupNews = true,
    this.events = false,
    this.pushEnabled = true,
    this.emailEnabled = true,
  });

  final bool investmentUpdates;
  final bool newOpportunities;
  final bool documents;
  final bool groupNews;
  final bool events;
  final bool pushEnabled;
  final bool emailEnabled;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        investmentUpdates: json['investment_updates'] as bool? ?? true,
        newOpportunities: json['new_opportunities'] as bool? ?? true,
        documents: json['documents'] as bool? ?? false,
        groupNews: json['group_news'] as bool? ?? true,
        events: json['events'] as bool? ?? false,
        pushEnabled: json['push_enabled'] as bool? ?? true,
        emailEnabled: json['email_enabled'] as bool? ?? true,
      );

  NotificationPreferences copyWith({
    bool? investmentUpdates,
    bool? newOpportunities,
    bool? documents,
    bool? groupNews,
    bool? events,
    bool? pushEnabled,
    bool? emailEnabled,
  }) =>
      NotificationPreferences(
        investmentUpdates: investmentUpdates ?? this.investmentUpdates,
        newOpportunities: newOpportunities ?? this.newOpportunities,
        documents: documents ?? this.documents,
        groupNews: groupNews ?? this.groupNews,
        events: events ?? this.events,
        pushEnabled: pushEnabled ?? this.pushEnabled,
        emailEnabled: emailEnabled ?? this.emailEnabled,
      );

  Map<String, dynamic> toUpdateMap() => {
        'investment_updates': investmentUpdates,
        'new_opportunities': newOpportunities,
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

Future<void> updateNotificationPreferences(
    WidgetRef ref, NotificationPreferences prefs) async {
  final userId = ref.read(currentUserIdProvider).valueOrNull;
  if (userId == null) return;
  await ref
      .read(supabaseClientProvider)
      .from('notification_preferences')
      .update(prefs.toUpdateMap())
      .eq('user_id', userId);
  ref.invalidate(notificationPreferencesProvider);
}
