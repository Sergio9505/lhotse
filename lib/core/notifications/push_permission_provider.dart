import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Mirror of the current OS push permission state. Updated by
/// `OneSignalService` on bind (initial read) and on every change emitted
/// by the SDK's `addPermissionObserver`.
final pushPermissionProvider = StateProvider<OSNotificationPermission>(
  (_) => OSNotificationPermission.notDetermined,
);
