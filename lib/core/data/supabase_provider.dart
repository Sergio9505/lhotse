import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/user_role.dart';
import '../../features/auth/domain/user_profile.dart';

// ─── Supabase client singleton ────────────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// ─── Raw auth event stream ────────────────────────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

// ─── Distinct userId stream ───────────────────────────────────────────────────
// CRITICAL: .distinct() prevents stale cache when user logs out and a different
// user logs in. See CLAUDE.md gotcha — never use currentUser directly.
final currentUserIdProvider = StreamProvider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange
      .map((state) => state.session?.user.id)
      .distinct();
});

// ─── User profile ─────────────────────────────────────────────────────────────
// Auto-invalidates when userId changes (logout → login as different user).
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return null;

  final data = await ref
      .watch(supabaseClientProvider)
      .from('user_profiles')
      .select()
      .eq('id', userId)
      .single();

  return UserProfile.fromJson(data);
});

// ─── Convenience: current role ────────────────────────────────────────────────
final currentUserRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(currentUserProfileProvider).valueOrNull?.role ??
      UserRole.viewer;
});
