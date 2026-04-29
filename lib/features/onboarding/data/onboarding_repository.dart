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
}
