import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

/// Outcome of a biometric authentication attempt.
///
/// Collapses the SDK's wider error space into the three buckets the rest of
/// the app actually cares about: success (let them in), userCancelled (they
/// tapped Cancel — keep the gate, or in soft-ask: skip), notAvailable (OS no
/// longer has biometrics enrolled — gracefully open the gate), failed (any
/// other transient error — let them retry).
enum BiometricResult { success, userCancelled, failed, notAvailable }

class BiometricService {
  BiometricService(this._auth);

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> availableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// `reason` is the line iOS / Android render inside the system sheet. Keep
  /// it short and accionable; the brand framing lives in our own UI behind it.
  Future<BiometricResult> authenticate({required String reason}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on Exception catch (e) {
      // The SDK throws PlatformException with `code` strings from
      // package:local_auth/error_codes.dart. Map the ones we have policy for.
      final code = _codeOf(e);
      if (code == auth_error.notAvailable ||
          code == auth_error.notEnrolled ||
          code == auth_error.passcodeNotSet) {
        return BiometricResult.notAvailable;
      }
      if (code == 'UserCancel' || code == 'userCancel') {
        return BiometricResult.userCancelled;
      }
      if (kDebugMode) debugPrint('[Biometric] auth failed: $e');
      return BiometricResult.failed;
    }
  }

  String? _codeOf(Object e) {
    try {
      return (e as dynamic).code as String?;
    } catch (_) {
      return null;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(LocalAuthentication());
});
