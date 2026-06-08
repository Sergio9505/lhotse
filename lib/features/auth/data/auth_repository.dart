import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/biometric_lock_controller.dart';
import '../../../core/data/supabase_provider.dart';
import '../../../core/utils/consent_metadata.dart';

class AuthRepository {
  AuthRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required bool marketingConsent,
    required ConsentMetadata meta,
  }) =>
      _client.auth.signUp(
        email: email,
        password: password,
        // Metadata keys consumed by `handle_new_user()` trigger:
        //   - first_name / last_name → user_profiles
        //   - marketing_consent + document_version_* + platform / os /
        //     app version → consent_log (3 initial rows: TC + Privacy
        //     + Marketing, both first two granted=true since the user
        //     must tick the legal checkbox to even reach signUp).
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'marketing_consent': marketingConsent,
          'document_version_terms':
              'https://lhotsegroup.com/es/terminos-y-condiciones-aplicacion-movil/',
          'document_version_privacy':
              'https://lhotsegroup.com/en/privacy-policy/',
          ...meta.toMap(),
        },
      );

  /// Append-only consent event (grant or revoke). Called from edit
  /// profile when the user toggles marketing, or from any future flow
  /// that updates a consent post-signup. IP + user-agent are populated
  /// server-side by the `record_consent` RPC.
  Future<void> recordConsent({
    required String consentType,
    required bool granted,
    required ConsentMetadata meta,
    String? documentVersion,
  }) async {
    await _client.rpc('record_consent', params: {
      'p_consent_type': consentType,
      'p_granted': granted,
      'p_document_version': documentVersion,
      'p_platform': meta.platform,
      'p_os_version': meta.osVersion,
      'p_app_version': meta.appVersion,
    });
  }

  Future<void> signOut() async {
    // Drop the in-memory unlock so a different user logging in on the same
    // device doesn't inherit the previous user's unlocked state.
    _ref.read(biometricLockControllerProvider.notifier).invalidateUnlock();
    await _client.auth.signOut();
  }

  /// Self-service account deletion (App Store / Play Store compliance).
  /// Calls the SECURITY DEFINER RPC that runs
  /// `DELETE FROM auth.users WHERE id = auth.uid()` — downstream cascades
  /// wipe user-side rows (profile, notifications, requests, onboarding,
  /// documents, sessions) and SET NULL the four contract tables, so the
  /// asset history stays anonymised. Once the RPC returns the DB session
  /// is already invalid (auth.sessions CASCADE); we call signOut to clear
  /// the local SDK state and the router's auth listener redirects to
  /// /welcome.
  Future<void> deleteMyAccount() async {
    await _client.rpc<dynamic>('delete_my_account');
    _ref.read(biometricLockControllerProvider.notifier).invalidateUnlock();
    await _client.auth.signOut();
  }

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

  // shouldCreateUser:false — without it, gotrue defaults to create_user:true on
  // the phone branch and silently creates an empty "ghost" account when the
  // phone is not yet in auth.users (e.g. admin-created accounts whose phone was
  // never written to auth.users.phone). Recovery must only target existing
  // accounts; a missing phone throws AuthException, handled by the screen.
  Future<void> sendPhoneOtp(String phone) =>
      _client.auth.signInWithOtp(phone: phone, shouldCreateUser: false);

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
  return AuthRepository(ref.watch(supabaseClientProvider), ref);
});
