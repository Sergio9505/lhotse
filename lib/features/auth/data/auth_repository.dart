import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_provider.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) =>
      _client.auth.signUp(
        email: email,
        password: password,
        phone: phone,
        data: {'full_name': fullName},
      );

  Future<void> signOut() => _client.auth.signOut();

  // ── Phone OTP (recovery + signup phone verification) ──

  Future<void> sendPhoneOtp(String phone) =>
      _client.auth.signInWithOtp(phone: phone);

  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) =>
      _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );

  Future<UserResponse> updatePassword(String newPassword) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));

  Future<ResendResponse> resendPhoneOtp(String phone) =>
      _client.auth.resend(type: OtpType.sms, phone: phone);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
