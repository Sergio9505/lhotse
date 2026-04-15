import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/brands_provider.dart';
import '../core/data/news_provider.dart';
import '../core/data/projects_provider.dart';
import '../core/data/supabase_provider.dart';
import '../core/domain/user_role.dart';
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
    if (state != AppLifecycleState.resumed) return;
    // Catalog
    ref.invalidate(brandsProvider);
    ref.invalidate(projectsProvider);
    ref.invalidate(newsProvider);
    ref.invalidate(featuredProjectsProvider);
    // User data
    ref.invalidate(brandSummariesProvider);
    ref.invalidate(portfolioSummaryProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidate(currentUserProfileProvider);
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
