import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/biometric_lock_controller.dart';
import '../core/boot/boot_state.dart';
import '../core/data/assets_provider.dart';
import '../core/data/brands_provider.dart';
import '../core/data/document_categories_provider.dart';
import '../core/data/documents_provider.dart';
import '../core/data/news_provider.dart';
import '../core/data/projects_provider.dart';
import '../core/data/supabase_provider.dart';
import '../core/notifications/onesignal_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/lhotse_text_scaler.dart';
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
    OneSignalService.bind(ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OneSignalService.flushPendingDeepLink();
    });
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

    // No preceding `paused` → o es cold start en iOS (callback nunca fire en
    // el estado inicial), o un system overlay que solo emite `inactive` (Face
    // ID prompt, control center, notification center, llamada entrante). En
    // ningún caso ha habido backgrounding real. Critical: si NO early-return
    // aquí, el `invalidateUnlock()` del bloque ≥5min borra el `_lastUnlockAt`
    // que el BiometricGateScreen acaba de setear tras una auth OK → la boot
    // machine vuelve a `BootPendingBiometric` → router redirige otra vez al
    // gate → bucle infinito. Ver post-mortem en el plan de Face ID.
    if (bg == null) return;

    final elapsed = DateTime.now().difference(bg);

    // Always: notifications + profile (change in minutes)
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidate(currentUserProfileProvider);

    // ≥ 5 min: investor positions + payments + documents + news.
    //   Data that reflects investment activity — admin uploads docs, coupons
    //   get paid, mortgage balances move. A stale L2 hides new cash flow.
    //   Also drops the in-memory biometric unlock so the boot state machine
    //   re-flips to `BootPendingBiometric` for opted-in users — router then
    //   redirects to /biometric-gate without any screen-level orchestration.
    if (elapsed >= const Duration(minutes: 5)) {
      ref.read(biometricLockControllerProvider.notifier).invalidateUnlock();
      ref.read(bootStateProvider.notifier).refresh();
      ref.invalidate(newsProvider);
      ref.invalidate(userPortfolioProvider);
      ref.invalidate(userPortfolioEntryProvider);
      ref.invalidate(purchaseContractsProvider);
      ref.invalidate(brandPurchaseContractsProvider);
      ref.invalidate(purchaseContractByIdProvider);
      ref.invalidate(coinvestmentContractsProvider);
      ref.invalidate(brandCoinvestmentContractsProvider);
      ref.invalidate(fixedIncomeContractsProvider);
      ref.invalidate(brandFixedIncomeContractsProvider);
      ref.invalidate(purchaseMortgageDetailProvider);
      ref.invalidate(documentsProvider);
      ref.invalidate(allUserDocumentsProvider);
    }

    // ≥ 1 hour: catalog + slow-moving metadata (physical asset info,
    //   project renders/economics, scenarios, phases, doc categories).
    if (elapsed >= const Duration(hours: 1)) {
      ref.invalidate(brandsProvider);
      ref.invalidate(projectsProvider);
      ref.invalidate(assetsProvider);
      ref.invalidate(purchaseAssetDetailProvider);
      ref.invalidate(coinvestmentProjectDetailProvider);
      ref.invalidate(projectScenariosProvider);
      ref.invalidate(projectPhasesProvider);
      ref.invalidate(allDocumentCategoriesProvider);
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
      builder: (context, child) {
        final media = MediaQuery.of(context);
        // Reverse-engineer the system scale factor from the inherited
        // TextScaler. Works for both linear and non-linear system scalers.
        final systemScale = media.textScaler.scale(14) / 14;
        return MediaQuery(
          data: media.copyWith(
            textScaler: LhotseTextScaler.fromSystem(systemScale),
          ),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
