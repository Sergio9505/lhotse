import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single async handle to the platform key-value store. Other modules
/// (OneSignal soft-ask counter, biometric lock controller, ...) read prefs
/// via this provider so the SharedPreferences instance — which on iOS goes
/// through NSUserDefaults — is initialised exactly once per app lifetime.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);
