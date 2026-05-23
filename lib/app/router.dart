import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/boot/boot_state.dart';
import '../core/domain/asset_data.dart';
import '../core/domain/brand_data.dart';
import '../core/domain/news_item_data.dart';
import '../core/domain/project_data.dart';
import '../core/auth/biometric_lock_controller.dart';
import '../features/auth/presentation/accept_consent_screen.dart';
import '../features/auth/presentation/biometric_gate_screen.dart';
import '../features/auth/presentation/complete_phone_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_verify_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/brands/presentation/brand_detail_screen.dart';
import '../features/brands/presentation/brands_screen.dart';
import '../features/home/presentation/asset_detail_screen.dart';
import '../features/home/presentation/news_detail_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/project_detail_screen.dart';
import '../features/investments/domain/completed_contract_data.dart';
import '../features/investments/domain/coinvestment_contract_data.dart';
import '../features/investments/domain/purchase_contract_data.dart';
import '../features/investments/presentation/brand_investments_screen.dart';
import '../features/investments/presentation/coinversion_detail_screen.dart';
import '../features/investments/presentation/direct_purchase_detail_screen.dart';
import '../features/investments/presentation/completed_detail_screen.dart';
import '../features/investments/presentation/investments_screen.dart';
import '../features/documents/presentation/document_loader_screen.dart';
import '../features/documents/presentation/document_preview_screen.dart';
import '../features/onboarding/presentation/onboarding_done_screen.dart';
import '../features/onboarding/presentation/onboarding_host.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/embedded_webview_screen.dart';
import '../features/profile/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/security_settings_screen.dart';
import '../features/search/presentation/search_screen.dart';
import 'shell_screen.dart';

CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
      opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
      child: child,
    ),
  );
}

abstract final class AppRoutes {
  // Boot
  static const splash = '/splash';
  // Auth
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  // Recovery / phone OTP (transient — accessible mid-flow)
  static const forgotPassword = '/forgot-password';
  static const otpVerify = '/otp-verify';
  static const resetPassword = '/reset-password';
  // Phone capture for sessions that landed without a verified phone (admin-
  // created users / pre-feature signups). Transient — owns its own nav.
  static const completePhone = '/complete-phone';
  // Consent gate for sessions whose user has no rows in `consent_log`
  // (admin-created users / pre-feature signups). Reached when the boot
  // state machine resolves to BootPendingConsent.
  static const acceptConsent = '/accept-consent';
  // Biometric unlock gate. Reached when the boot state machine resolves to
  // BootPendingBiometric (user opted in to Face ID / Touch ID / fingerprint
  // and cold-start / 5-min-background invalidated the in-memory unlock).
  static const biometricGate = '/biometric-gate';
  // Onboarding (post sign-up, outside shell)
  static const onboarding = '/onboarding';
  static const onboardingDone = '/onboarding/done';
  // Main app
  static const home = '/';
  static const newsDetail = '/news/:id';
  static const projectDetail = '/projects/:id';
  static const assetDetail = '/assets/:id';
  static const brands = '/brands';
  static const brandDetail = '/brands/:id';
  static const search = '/search';
  static const investments = '/investments';
  static const brandInvestments = '/investments/brand/:brandId';
  static const purchaseDetail = '/investments/detail/purchase/:id';
  static const coinvestmentDetail = '/investments/detail/coinvestment/:id';
  static const completedPurchaseDetail = '/investments/detail/completed/purchase/:id';
  static const completedCoinvestmentDetail = '/investments/detail/completed/coinvestment/:id';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileNotifications = '/profile/notifications';
  static const profileSupport = '/profile/support';
  static const profileTerms = '/profile/terms';
  static const profilePrivacy = '/profile/privacy';
  static const profileSecurity = '/profile/security';
  static const documentPreview = '/document-preview';
  static const documentById = '/documents/:id';
}

/// Routes shown when the user is signed out (welcome + auth forms).
const _kAuthRoutes = {
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.forgotPassword,
};

/// Public legal pages (terms/privacy/support web views) reachable from the
/// signup consent checkbox before the user has an account. Bypass the gate
/// in every boot state.
const _kPublicLegalRoutes = {
  AppRoutes.profileTerms,
  AppRoutes.profilePrivacy,
  AppRoutes.profileSupport,
};

/// Transient routes inside a multi-step flow (OTP, reset password, complete
/// phone). The owning screen drives navigation; the router only allows them
/// when the current boot state is compatible.
const _kTransientAuthRoutes = {
  AppRoutes.otpVerify,
  AppRoutes.resetPassword,
  AppRoutes.completePhone,
};

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Capture the user's current location before bouncing them to the biometric
/// gate so [BootReady] can restore it after a successful unlock. Without
/// this, every gate would land the user on Home regardless of where they
/// were heading (deep links, /investments mid-session timeout, etc.).
String _captureAndRedirectToBiometricGate(Ref ref, String loc) {
  ref
      .read(biometricLockControllerProvider.notifier)
      .capturePendingDestination(loc);
  return AppRoutes.biometricGate;
}

/// Post-`BootReady` redirect helper. Handles three transitions:
///   - auth/consent screens → home (the user shouldn't sit on a /login
///     screen once they're authed),
///   - biometric gate → captured pending destination (or home),
///   - everything else → stay put.
String? _bootReadyRedirect(Ref ref, String loc) {
  if (_kAuthRoutes.contains(loc) || loc == AppRoutes.acceptConsent) {
    return AppRoutes.home;
  }
  if (loc == AppRoutes.biometricGate) {
    final dest = ref
        .read(biometricLockControllerProvider.notifier)
        .consumePendingDestination();
    return dest ?? AppRoutes.home;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge BootState → GoRouter.refreshListenable. Any change in the boot
  // state machine triggers the redirect to re-evaluate.
  final bootNotifier = ValueNotifier<int>(0);
  ref.listen(bootStateProvider, (_, _) => bootNotifier.value++);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: bootNotifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Splash + legal pages own their own lifecycle — no router
      // interference. SplashScreen plays the brand video + fade in full,
      // then explicitly hands off via `context.go(...)`; the router
      // re-evaluates at that point with the final bootState. Without this
      // early-return the router would teleport the user out of /splash the
      // moment bootState != Loading, killing the intro video.
      if (loc == AppRoutes.splash) return null;
      if (_kPublicLegalRoutes.contains(loc)) return null;

      final boot = ref.read(bootStateProvider);

      return switch (boot) {
        // Any non-splash route during initial loading bounces back to
        // splash; in practice this can't happen because /splash is the
        // initialLocation and nothing else navigates to /splash.
        BootLoading() => AppRoutes.splash,
        BootSignedOut() => (_kAuthRoutes.contains(loc) ||
                _kTransientAuthRoutes.contains(loc))
            ? null
            : AppRoutes.welcome,
        BootPendingPhone() => (loc == AppRoutes.signup ||
                loc == AppRoutes.completePhone ||
                loc == AppRoutes.otpVerify)
            ? null
            : AppRoutes.completePhone,
        BootPendingConsent() =>
            loc == AppRoutes.acceptConsent ? null : AppRoutes.acceptConsent,
        BootPendingOnboarding() => (loc == AppRoutes.onboarding ||
                loc == AppRoutes.onboardingDone)
            ? null
            : AppRoutes.onboarding,
        BootPendingBiometric() => loc == AppRoutes.biometricGate
            ? null
            : _captureAndRedirectToBiometricGate(ref, loc),
        BootReady() => _bootReadyRedirect(ref, loc),
      };
    },
    routes: [
      // ── Boot ──
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      // ── Auth routes (outside shell — no bottom nav) ──
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        pageBuilder: (context, state) {
          // args may be null when the router redirects an unverified-phone
          // session here directly — OtpVerifyScreen falls back to the
          // current user's phone in that case.
          final args = state.extra as OtpVerifyArgs?;
          return _fadePage(
            key: state.pageKey,
            child: OtpVerifyScreen(args: args),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const ResetPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.completePhone,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const CompletePhoneScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.acceptConsent,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const AcceptConsentScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.biometricGate,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: BiometricGateScreen(),
        ),
      ),
      // ── Document preview (outside shell — full-screen, any feature) ──
      GoRoute(
        path: AppRoutes.documentPreview,
        pageBuilder: (context, state) {
          final extra = state.extra as ({
            String localPath,
            String displayName,
            String? subtitle,
          });
          return _fadePage(
            key: state.pageKey,
            child: DocumentPreviewScreen(
              localPath: extra.localPath,
              displayName: extra.displayName,
              subtitle: extra.subtitle,
            ),
          );
        },
      ),
      // ── Document loader (push-notification deep link) ──
      // Fetches the doc row by id, downloads, then pushReplaces with
      // /document-preview. Lives outside the shell because the preview
      // is full-screen too.
      GoRoute(
        path: AppRoutes.documentById,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _fadePage(
            key: state.pageKey,
            child: DocumentLoaderScreen(documentId: id),
          );
        },
      ),
      // ── Onboarding (post sign-up, authenticated, outside shell) ──
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const OnboardingHost(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingDone,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: OnboardingDoneScreen(),
        ),
      ),
      // ── Main app shell ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.newsDetail,
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                final initialNews = state.extra is NewsItemData
                    ? state.extra as NewsItemData
                    : null;
                return _fadePage(
                  key: state.pageKey,
                  child: NewsDetailScreen(
                    newsId: id,
                    initialNews: initialNews,
                  ),
                );
              },
            ),
            GoRoute(
              path: AppRoutes.projectDetail,
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                final initialProject = state.extra is ProjectData
                    ? state.extra as ProjectData
                    : null;
                return _fadePage(
                  key: state.pageKey,
                  child: ProjectDetailScreen(
                    projectId: id,
                    initialProject: initialProject,
                  ),
                );
              },
            ),
            GoRoute(
              path: AppRoutes.assetDetail,
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                final initialAsset = state.extra is AssetData
                    ? state.extra as AssetData
                    : null;
                return _fadePage(
                  key: state.pageKey,
                  child: AssetDetailScreen(
                    assetId: id,
                    initialAsset: initialAsset,
                  ),
                );
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.brands,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: BrandsScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.brandDetail,
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                final initialBrand = state.extra is BrandData
                    ? state.extra as BrandData
                    : null;
                return _fadePage(
                  key: state.pageKey,
                  child: BrandDetailScreen(
                    brandId: id,
                    initialBrand: initialBrand,
                  ),
                );
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.search,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SearchScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.investments,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: InvestmentsScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.brandInvestments,
              pageBuilder: (context, state) {
                final brandId = state.pathParameters['brandId']!;
                final heroContext =
                    state.extra as ({String brandName, String businessModel})?;
                return _fadePage(
                  key: state.pageKey,
                  child: BrandInvestmentsScreen(
                    brandId: brandId,
                    heroContext: heroContext,
                  ),
                );
              },
            ),
            GoRoute(
              path: AppRoutes.purchaseDetail,
              pageBuilder: (context, state) {
                final extra = state.extra as ({
                  PurchaseContractData contract,
                  String brandName,
                })?;
                return _fadePage(
                  key: state.pageKey,
                  child: DirectPurchaseDetailScreen(
                    contractId: state.pathParameters['id']!,
                    brandName: extra?.brandName,
                    contract: extra?.contract,
                  ),
                );
              },
            ),
            GoRoute(
              path: AppRoutes.coinvestmentDetail,
              pageBuilder: (context, state) {
                final extra = state.extra as ({
                  CoinvestmentContractData contract,
                  String brandName,
                });
                return _fadePage(
                  key: state.pageKey,
                  child: CoinversionDetailScreen(
                    contract: extra.contract,
                    brandName: extra.brandName,
                  ),
                );
              },
            ),
            GoRoute(
              path: AppRoutes.completedPurchaseDetail,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: CompletedDetailScreen(
                  data: state.extra as CompletedContractData,
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.completedCoinvestmentDetail,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: CompletedDetailScreen(
                  data: state.extra as CompletedContractData,
                ),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.profileEdit,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: const EditProfileScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.profileNotifications,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: const NotificationsScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.profileSecurity,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: const SecuritySettingsScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.profileSupport,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: const EmbeddedWebViewScreen(
                  url: 'https://lhotsegroup.com/es/soporte-app/',
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.profileTerms,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: const EmbeddedWebViewScreen(
                  url:
                      'https://lhotsegroup.com/es/terminos-y-condiciones-aplicacion-movil/',
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.profilePrivacy,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: const EmbeddedWebViewScreen(
                  url: 'https://lhotsegroup.com/en/privacy-policy/',
                ),
              ),
            ),
          ]),
        ],
      ),
    ],
  );
});
