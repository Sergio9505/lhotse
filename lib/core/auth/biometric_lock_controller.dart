import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/supabase_provider.dart';
import 'biometric_service.dart';

/// Persisted slice of the biometric lock state for the current user.
///
/// `enabled` is tri-state:
///   - `null`   — never decided; soft-ask will appear in Home (subject to cap).
///   - `true`   — opt-in active; hard gate enforced on cold start and after
///                 5 minutes in background.
///   - `false`  — explicitly off; gate never appears for this user.
class BiometricLockState {
  const BiometricLockState({this.enabled, this.softAskCount = 0});

  final bool? enabled;
  final int softAskCount;
}

/// Hard cap on the number of times the branded soft-ask sheet appears for a
/// given user across the app's lifetime. Mirrors the push opt-in policy
/// (see [OneSignalService] — 2 lifetime). Past the cap, activation only
/// happens explicitly from Perfil > Seguridad.
const _softAskHardCap = 2;

/// Re-auth window. After this much time in background, the next resume
/// invalidates the unlock timestamp and the boot machine flips back to
/// BootPendingBiometric.
const _reauthAfter = Duration(minutes: 5);

class BiometricLockController extends AsyncNotifier<BiometricLockState> {
  // In-memory — intentionally NOT persisted. Cold start forces re-auth.
  DateTime? _lastUnlockAt;
  bool _softAskShownThisSession = false;
  String? _pendingDestination;

  /// Cached so the auth-event listener can no-op when the same user emits
  /// repeated events (initial `signedIn`, token refresh, etc.). Reloading
  /// prefs is only meaningful when the active user actually changes.
  String? _lastSeenUserId;

  /// Monotonic counter mirroring `BootStateNotifier._refreshSeq`: two auth
  /// events in rapid succession (signedIn + tokenRefreshed) trigger two
  /// concurrent reloads; only the latest commits.
  int _reloadSeq = 0;

  String? _userId() =>
      ref.read(supabaseClientProvider).auth.currentSession?.user.id;

  String _enabledKey(String uid) => 'biometric.enabled.$uid';
  String _softAskCountKey(String uid) => 'biometric.softAskCount.$uid';

  @override
  Future<BiometricLockState> build() async {
    // CRITICAL — do NOT call `ref.invalidateSelf()` from this listener. That
    // re-runs build() which re-subscribes, the new subscription receives the
    // initial session event, the listener invalidates again → infinite loop
    // and `provider.future` never resolves. Boot state stays in BootLoading
    // forever, the splash never hands off, and the user is stuck on a black
    // screen. (See ADR-77 + the Riverpod foot-guns block in CLAUDE.md.)
    //
    // Instead: track the userId, no-op on duplicate events, and update
    // `state` in place when the user actually changes. Same pattern as
    // `BootStateNotifier`.
    final client = ref.watch(supabaseClientProvider);
    final sub = client.auth.onAuthStateChange.listen((event) {
      final newUid = event.session?.user.id;
      if (newUid == _lastSeenUserId) return;
      _lastSeenUserId = newUid;
      _lastUnlockAt = null;
      _softAskShownThisSession = false;
      _pendingDestination = null;
      _reload();
    });
    ref.onDispose(sub.cancel);

    _lastSeenUserId = _userId();
    return _loadForCurrentUser();
  }

  Future<BiometricLockState> _loadForCurrentUser() async {
    final uid = _userId();
    if (uid == null) return const BiometricLockState();
    final prefs = await SharedPreferences.getInstance();
    final bool? enabled = prefs.containsKey(_enabledKey(uid))
        ? prefs.getBool(_enabledKey(uid))
        : null;
    final count = prefs.getInt(_softAskCountKey(uid)) ?? 0;
    return BiometricLockState(enabled: enabled, softAskCount: count);
  }

  /// In-place state refresh — does NOT trigger a Notifier rebuild. Safe to
  /// call from listeners. `_reloadSeq` discards stale concurrent reloads.
  Future<void> _reload() async {
    final seq = ++_reloadSeq;
    final next = await AsyncValue.guard(_loadForCurrentUser);
    if (seq != _reloadSeq) return;
    state = next;
  }

  // ── Decisions ────────────────────────────────────────────────────────────

  /// Synchronous decision used by `BootStateNotifier.refresh()`. Returns
  /// `true` only when the user has opted-in and we're outside the re-auth
  /// window (or we've never unlocked this app lifetime).
  bool requiresUnlockNow() {
    final s = state.valueOrNull;
    if (s?.enabled != true) return false;
    final last = _lastUnlockAt;
    if (last == null) return true;
    return DateTime.now().difference(last) > _reauthAfter;
  }

  /// `true` only when: never decided + under the soft-ask cap + biometrics
  /// actually available on the device + haven't shown the sheet this session.
  Future<bool> shouldShowSoftAsk() async {
    final s = state.valueOrNull;
    if (s == null) return false;
    if (s.enabled != null) return false;
    if (s.softAskCount >= _softAskHardCap) return false;
    if (_softAskShownThisSession) return false;
    return ref.read(biometricServiceProvider).isAvailable();
  }

  // ── Soft-ask flow ────────────────────────────────────────────────────────

  /// Called when the soft-ask sheet opens. Marks the in-memory guard and
  /// bumps the persisted lifetime counter — a dismissed sheet still counts,
  /// matching the push policy.
  Future<void> markSoftAskShown() async {
    _softAskShownThisSession = true;
    final uid = _userId();
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_softAskCountKey(uid)) ?? 0;
    final next = current + 1;
    await prefs.setInt(_softAskCountKey(uid), next);
    state = AsyncData(BiometricLockState(
      enabled: state.valueOrNull?.enabled,
      softAskCount: next,
    ));
  }

  /// User tapped "Más tarde" on the soft-ask. No persisted change to
  /// `enabled` (stays `null` — eligible to re-prompt until cap). The session
  /// guard set in [markSoftAskShown] keeps the sheet from re-firing now.
  void deferSoftAsk() {
    // No-op; markSoftAskShown already incremented + flipped the session guard.
  }

  // ── Activation / deactivation ────────────────────────────────────────────

  /// Fires the OS biometric prompt and, on success, persists `enabled = true`
  /// + marks an unlock timestamp so the just-activated user doesn't hit a
  /// hard gate on the very next refresh.
  Future<bool> activate({required String reason}) async {
    final result = await ref
        .read(biometricServiceProvider)
        .authenticate(reason: reason);
    if (result == BiometricResult.success) {
      await _persistEnabled(true);
      _lastUnlockAt = DateTime.now();
      return true;
    }
    return false;
  }

  /// Explicit opt-out (toggle off in Settings; OS no longer has biometrics
  /// enrolled and the gate detected it). Suppresses any future gate without
  /// removing the per-user counter — re-activation from Settings is fine.
  Future<void> disableExplicitly() async {
    await _persistEnabled(false);
    _lastUnlockAt = DateTime.now();
  }

  Future<void> _persistEnabled(bool value) async {
    final uid = _userId();
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey(uid), value);
    state = AsyncData(BiometricLockState(
      enabled: value,
      softAskCount: state.valueOrNull?.softAskCount ?? 0,
    ));
  }

  // ── Unlock lifecycle ─────────────────────────────────────────────────────

  void markUnlocked() {
    _lastUnlockAt = DateTime.now();
  }

  void invalidateUnlock() {
    _lastUnlockAt = null;
  }

  // ── Pending destination (restore after gate) ─────────────────────────────

  void capturePendingDestination(String loc) {
    _pendingDestination = loc;
  }

  String? consumePendingDestination() {
    final out = _pendingDestination;
    _pendingDestination = null;
    return out;
  }
}

final biometricLockControllerProvider =
    AsyncNotifierProvider<BiometricLockController, BiometricLockState>(
  BiometricLockController.new,
);
