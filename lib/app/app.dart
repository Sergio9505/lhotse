import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/brands_provider.dart';
import '../core/data/news_provider.dart';
import '../core/data/projects_provider.dart';
import '../core/data/supabase_provider.dart';
import '../core/theme/app_theme.dart';
import '../features/investments/data/investments_provider.dart';
import '../features/notifications/data/notifications_provider.dart';
import 'router.dart';

class LhotseApp extends ConsumerStatefulWidget {
  const LhotseApp({super.key});

  @override
  ConsumerState<LhotseApp> createState() => _LhotseAppState();
}

class _LhotseAppState extends ConsumerState<LhotseApp>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final bg = _backgroundedAt;
    _backgroundedAt = null;
    final elapsed = bg != null
        ? DateTime.now().difference(bg)
        : const Duration(hours: 24); // app killed → treat as very long

    // Always: notifications + profile (change in minutes)
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidate(currentUserProfileProvider);

    // ≥ 5 min: investment summaries + news
    if (elapsed >= const Duration(minutes: 5)) {
      ref.invalidate(newsProvider);
      ref.invalidate(brandSummariesProvider);
      ref.invalidate(portfolioSummaryProvider);
    }

    // ≥ 1 hour: catalog (brands, projects, featured carousel)
    if (elapsed >= const Duration(hours: 1)) {
      ref.invalidate(brandsProvider);
      ref.invalidate(projectsProvider);
      ref.invalidate(featuredProjectsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Lhotse Group',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
