import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/data/assets_provider.dart';
import '../../../core/data/brands_provider.dart';
import '../../../core/data/document_categories_provider.dart';
import '../../../core/data/documents_provider.dart';
import '../../../core/data/news_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../investments/data/investments_provider.dart';

/// First screen after the native bootstrap. Plays a Lottie motion while
/// warming up the critical Riverpod providers so that any tab the user
/// jumps into first (Buscar, Estrategia…) has data ready.
///
/// TODO: when the designer delivers `lhotse_splash.json`, drop it in
/// `assets/animations/` + register in pubspec + swap `Lottie.network(...)`
/// for `Lottie.asset(...)` below. Also consider `flutter_native_splash`
/// with a matching first-frame PNG for a fully seamless cold start.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // Stable public Lottie sample from the lottie-flutter package repo.
  // Placeholder — will be replaced with the branded Lhotse motion.
  static const _placeholderLottieUrl =
      'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Logo/LogoSmall.json';

  static const _minSplashDuration = Duration(milliseconds: 3000);
  static const _warmUpTimeout = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Flutter has rendered its first frame — dismiss the native splash so
      // the Lottie becomes visible. The transition is continuous because
      // both stages share the same centered-logo-on-black visual.
      FlutterNativeSplash.remove();
      _warmUpAndNavigate();
    });
  }

  /// Runs a future and swallows any error. Returns `Future<void>` so all
  /// warm-up tasks share a single signature regardless of provider type.
  Future<void> _safe(Future<Object?> future) async {
    try {
      await future;
    } catch (_) {
      // Individual provider errors are not blocking the splash. Each screen
      // will surface its own error state when the user navigates there.
    }
  }

  Future<void> _warmUpAndNavigate() async {
    final authed = Supabase.instance.client.auth.currentUser != null;

    // featuredProjectsProvider is family by UserRole — fetched lazily by
    // the home screen once the user profile resolves. Not warmed here.
    final futures = <Future<void>>[
      _safe(ref.read(brandsProvider.future)),
      _safe(ref.read(projectsProvider.future)),
      _safe(ref.read(assetsProvider.future)),
      _safe(ref.read(allDocumentCategoriesProvider.future)),
      _safe(ref.read(newsProvider.future)),
      Future<void>.delayed(_minSplashDuration),
    ];

    if (authed) {
      futures.addAll([
        _safe(ref.read(allUserDocumentsProvider.future)),
        _safe(ref.read(purchaseContractsProvider.future)),
        _safe(ref.read(coinvestmentContractsProvider.future)),
        _safe(ref.read(fixedIncomeContractsProvider.future)),
        _safe(ref.read(userPortfolioProvider.future)),
      ]);
    }

    try {
      await Future.wait(futures).timeout(_warmUpTimeout);
    } catch (_) {
      // Timeout — navigate anyway; each screen re-fetches what it needs.
    }

    if (!mounted) return;
    context.go(authed ? AppRoutes.home : AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: SizedBox(
          width: 180,
          height: 180,
          child: Lottie.network(
            _placeholderLottieUrl,
            fit: BoxFit.contain,
            repeat: true,
            errorBuilder: (context, _, _) => _StaticLogoFallback(),
            // While the JSON downloads on first cold-boot with network,
            // show the static logo so the screen is never empty.
            frameBuilder: (context, child, composition) =>
                composition == null ? _StaticLogoFallback() : child,
          ),
        ),
      ),
    );
  }
}

class _StaticLogoFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.asset(
        'assets/images/lhotse_logo.svg',
        width: 120,
        colorFilter: const ColorFilter.mode(
          AppColors.textOnDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
