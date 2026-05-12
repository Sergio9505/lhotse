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
  }) =>
      _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

  Future<void> signOut() => _client.auth.signOut();

  // ── Phone OTP ──
  //
  // Two distinct flows share the OTP screen:
  //
  // 1) Signup 2FA: the account is created by [signUp] (email + password).
  //    Then [attachPhone] adds the phone via auth.updateUser, which makes
  //    Supabase send the SMS via Twilio automatically. The user verifies
  //    via [verifyPhoneChangeOtp] (OtpType.phoneChange).
  //
  // 2) Password recovery: there is no session. [sendPhoneOtp] uses
  //    signInWithOtp to send an SMS; the user verifies via [verifyPhoneOtp]
  //    (OtpType.sms), which creates a session, then resets the password.

  Future<UserResponse> attachPhone(String phone) =>
      _client.auth.updateUser(UserAttributes(phone: phone));

  Future<AuthResponse> verifyPhoneChangeOtp({
    required String phone,
    required String token,
  }) =>
      _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.phoneChange,
      );

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

  /// Returns the phone number the user attempted to attach during signup
  /// but never verified (auth.users.phone_change). Returns null if the
  /// user is fully verified or has no pending change. Used to resume the
  /// OTP flow after a force-quit / device switch — the gotrue SDK does
  /// not expose phone_change locally, so we read it via a SECURITY DEFINER
  /// RPC (`get_pending_phone`).
  Future<String?> getPendingPhone() async {
    final result = await _client.rpc<dynamic>('get_pending_phone');
    if (result == null) return null;
    final str = result.toString();
    return str.isEmpty ? null : str;
  }

  /// Resends the SMS OTP. Uses [OtpType.phoneChange] when the user already
  /// has a session (signup 2FA), [OtpType.sms] otherwise (password recovery).
  Future<ResendResponse> resendPhoneOtp(
    String phone, {
    bool isPhoneChange = false,
  }) =>
      _client.auth.resend(
        type: isPhoneChange ? OtpType.phoneChange : OtpType.sms,
        phone: phone,
      );
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
