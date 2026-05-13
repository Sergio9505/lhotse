import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../app/router.dart' show rootNavigatorKey;
import '../../features/notifications/data/notifications_provider.dart';
import '../data/supabase_provider.dart';

/// Bridge between the OneSignal SDK and the rest of the app.
///
/// Lifecycle:
///   1. [initializeSdk] is called from `main.dart` before `runApp`. If
///      `ONESIGNAL_APP_ID` is not provided as a dart-define, the SDK is
///      skipped silently so dev builds without push credentials still work.
///   2. [bind] is called once from `LhotseApp.initState`. It wires:
///        - `currentUserIdProvider` → `OneSignal.login()` / `OneSignal.logout()`
///        - foreground listener → invalidates the in-app feed providers
///        - click listener → resolves `additionalData.deep_link` to a GoRouter
///          path. Cold-start clicks (no nav context yet) are queued and
///          flushed by [flushPendingDeepLink] after the first frame.
class OneSignalService {
  OneSignalService._();

  static String? _pendingDeepLink;
  static bool _bound = false;

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
  }

  /// Requests iOS push permission. Call after onboarding finishes.
  static Future<bool> requestPermission() async {
    if (!_configured) return false;
    return OneSignal.Notifications.requestPermission(true);
  }

  static void _navigate(String path) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) {
      _pendingDeepLink = path;
      return;
    }
    try {
      ctx.go(path);
    } catch (e) {
      if (kDebugMode) debugPrint('[OneSignal] nav failed for "$path": $e');
    }
  }

  /// Consume any deep link queued before the router was ready (cold start).
  static void flushPendingDeepLink() {
    final pending = _pendingDeepLink;
    if (pending == null) return;
    _pendingDeepLink = null;
    _navigate(pending);
  }
}
