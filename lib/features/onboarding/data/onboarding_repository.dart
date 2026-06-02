import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(),
);

class OnboardingRepository {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  Future<void> upsertAnswer(String column, dynamic value) async {
    await _supabase.from('user_onboarding').upsert(
      {
        'user_id': _userId,
        column: value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  Future<void> markCompleted() async {
    await _supabase.from('user_onboarding').upsert(
      {
        'user_id': _userId,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  /// Whether the user has already watched (or skipped) the one-time CEO
  /// welcome video. Per-account state (survives reinstall / device change),
  /// co-located with onboarding completion in `user_onboarding`. The caller
  /// fails open — a read error must NOT block the user — so this throws and
  /// the orchestrator treats failures as "don't show".
  Future<bool> hasSeenWelcome() async {
    final row = await _supabase
        .from('user_onboarding')
        .select('welcome_seen_at')
        .eq('user_id', _userId)
        .maybeSingle();
    return row?['welcome_seen_at'] != null;
  }

  /// Stamp the welcome video as seen. Idempotent via upsert on `user_id`.
  Future<void> markWelcomeSeen() async {
    await _supabase.from('user_onboarding').upsert(
      {
        'user_id': _userId,
        'welcome_seen_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }
}
