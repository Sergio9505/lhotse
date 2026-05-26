import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/notifications/onesignal_service.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Hold the native splash until the Flutter SplashScreen is ready to show
  // its own frame — avoids a black flash between native and Flutter.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Generous image cache: 500 MB bytes (default 100 MB) and 2000 entries
  // (default 1000). Detail screens precache all media up-front; the higher
  // ceilings let `Image(image: CachedNetworkImageProvider(...))` deliver
  // synchronous warm-cache hits via `frameBuilder.wasSynchronouslyLoaded`
  // across long sessions. The byte budget is the real pressure release: a
  // single fullscreen hero decodes to ~17 MB on 3x DPR, so 200 MB used to
  // get exhausted within a few detail visits and brand thumbnails got
  // LRU-evicted — visible as random 1-3s "back from cache" loads when
  // returning to Firmas. 500 MB is a normal range for premium image-heavy
  // apps (Pinterest ~500 MB, Instagram 450-800 MB) and `iOS` reclaims it
  // automatically on memory pressure.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 500 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 2000;

  await initializeDateFormatting('es_ES', null);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  await OneSignalService.initializeSdk();

  runApp(
    const ProviderScope(
      child: LhotseApp(),
    ),
  );
}
