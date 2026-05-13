import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/router.dart' show rootNavigatorKey;
import '../../features/notifications/data/notifications_provider.dart';
import '../data/supabase_provider.dart';
import 'deep_link_resolver.dart';
import 'push_permission_provider.dart';

/// Bridge between the OneSignal SDK and the rest of the app.
///
/// Lifecycle:
///   1. [initializeSdk] is called from `main.dart` before `runApp`. If
///      `ONESIGNAL_APP_ID` is not provided as a dart-define, the SDK is
///      skipped silently so dev builds without push credentials still work.
///   2. [bind] is called once from `LhotseApp.initState`. It wires:
///        - `currentUserIdProvider` → `OneSignal.login()` / `OneSignal.logout()`.
///        - foreground listener → invalidates the in-app feed providers.
///        - click listener → resolves `additionalData.deep_link` to a GoRouter
///          path. Cold-start clicks are queued and flushed by
///          [flushPendingDeepLink] after the first frame.
///        - permission observer → publishes to `pushPermissionProvider` so
///          banners and the soft-ask UI react without polling.
///
/// Persistence (`shared_preferences`):
///   - `push_soft_ask_count` (int) — number of times the user has been shown
///     the custom soft-ask sheet. Hard cap of 2 (premium anti-nag).
///   - `push_denied_banner_dismissed_at` (ISO8601 string) — last time the
///     user dismissed the "Activar en Ajustes" banner. Cooldown of 7 days.
class OneSignalService {
  OneSignalService._();

  static const _kSoftAskCount = 'push_soft_ask_count';
  static const _kDeniedBannerDismissedAt = 'push_denied_banner_dismissed_at';
  static const _softAskHardCap = 2;
  static const _deniedBannerCooldown = Duration(days: 7);

  static String? _pendingDeepLink;
  static bool _bound = false;
  static WidgetRef? _ref;

  /// In-memory guard so the soft-ask doesn't reappear within the same session
  /// regardless of where it would otherwise auto-trigger.
  static bool softAskShownThisSession = false;

  static String get _appId =>
      const String.fromEnvironment('ONESIGNAL_APP_ID');

  static bool get _configured => _appId.isNotEmpty;

  static Future<void> initializeSdk() async {
    if (!_configured) {
      if (kDebugMode) {
        debugPrint('[OneSignal] ONESIGNAL_APP_ID empty — push disabled');
      }
      return;
    }
    OneSignal.initialize(_appId);
  }

  static void bind(WidgetRef ref) {
    if (_bound || !_configured) return;
    _bound = true;
    _ref = ref;

    ref.listenManual<AsyncValue<String?>>(
      currentUserIdProvider,
      (prev, next) {
        next.whenData((userId) async {
          if (userId == null) {
            await OneSignal.logout();
          } else {
            await OneSignal.login(userId);
          }
        });
      },
      fireImmediately: true,
    );

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    });

    OneSignal.Notifications.addClickListener((event) {
      final raw = event.notification.additionalData?['deep_link'];
      final link = raw is String && raw.isNotEmpty ? raw : '/';
      _navigate(link);
    });

    // Initial snapshot + reactive updates whenever permission changes
    // (user accepts the system dialog, toggles in Settings, etc.).
    _publishPermission();
    OneSignal.Notifications.addPermissionObserver((_) => _publishPermission());
  }

  static Future<void> _publishPermission() async {
    if (!_configured) return;
    final ref = _ref;
    if (ref == null) return;
    try {
      final p = await OneSignal.Notifications.permissionNative();
      ref.read(pushPermissionProvider.notifier).state = p;
    } catch (e) {
      if (kDebugMode) debugPrint('[OneSignal] permissionNative failed: $e');
    }
  }

  /// Triggers the iOS/Android system dialog. Only call after the user has
  /// pulled the trigger on the custom soft-ask sheet. If status is already
  /// `denied`, `fallbackToSettings=true` redirects to the OS Settings app
  /// instead of silently no-op'ing.
  static Future<bool> requestPermission() async {
    if (!_configured) return false;
    return OneSignal.Notifications.requestPermission(true);
  }

  /// Opens the system push settings for this app. Re-uses
  /// `requestPermission(fallbackToSettings: true)` — when permission is
  /// `denied` the SDK opens Settings directly; in other states it's a no-op
  /// or harmless re-ask.
  static Future<void> openSystemPushSettings() async {
    if (!_configured) return;
    await OneSignal.Notifications.requestPermission(true);
  }

  // ── Soft-ask persistence ────────────────────────────────────────────────

  static Future<int> softAskCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSoftAskCount) ?? 0;
  }

  static Future<void> incrementSoftAskCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_kSoftAskCount) ?? 0;
    await prefs.setInt(_kSoftAskCount, current + 1);
  }

  /// True if we still have headroom to show the soft-ask sheet:
  /// SDK is configured, not shown yet this session, lifetime count below
  /// the hard cap, AND OS permission is still `notDetermined` (asking
  /// when already authorized/denied is pointless).
  static Future<bool> canShowSoftAsk() async {
    if (!_configured) return false;
    if (softAskShownThisSession) return false;
    final count = await softAskCount();
    if (count >= _softAskHardCap) return false;
    try {
      final perm = await OneSignal.Notifications.permissionNative();
      return perm == OSNotificationPermission.notDetermined;
    } catch (_) {
      return false;
    }
  }

  // ── Denied banner cooldown ──────────────────────────────────────────────

  static Future<DateTime?> deniedBannerDismissedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDeniedBannerDismissedAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> markDeniedBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kDeniedBannerDismissedAt,
      DateTime.now().toIso8601String(),
    );
  }

  /// True if the user is currently `denied` and either has never dismissed
  /// the banner or the cooldown has elapsed.
  static Future<bool> shouldShowDeniedBanner() async {
    final ref = _ref;
    if (ref == null) return false;
    if (ref.read(pushPermissionProvider) != OSNotificationPermission.denied) {
      return false;
    }
    final dismissedAt = await deniedBannerDismissedAt();
    if (dismissedAt == null) return true;
    return DateTime.now().difference(dismissedAt) > _deniedBannerCooldown;
  }

  // ── Deep link navigation ────────────────────────────────────────────────

  static void _navigate(String path) {
    final ref = _ref;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || ref == null) {
      _pendingDeepLink = path;
      return;
    }
    // Smart resolver: project/asset deep-links may land on user's L3 instead
    // of the public L1 depending on their contracts. News / documents pass
    // through unchanged.
    resolveAndNavigate(path, ref).catchError((Object e) {
      if (kDebugMode) debugPrint('[OneSignal] resolve failed for "$path": $e');
    });
  }

  /// Consume any deep link queued before the router was ready (cold start).
  static void flushPendingDeepLink() {
    final pending = _pendingDeepLink;
    if (pending == null) return;
    _pendingDeepLink = null;
    _navigate(pending);
  }
}
