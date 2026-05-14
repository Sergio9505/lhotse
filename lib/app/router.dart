import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/data/supabase_provider.dart';
import '../core/domain/asset_data.dart';
import '../core/domain/brand_data.dart';
import '../core/domain/news_item_data.dart';
import '../core/domain/project_data.dart';
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
import '../features/profile/presentation/legal_text_screen.dart';
import '../features/profile/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/support_screen.dart';
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
  static const documentPreview = '/document-preview';
  static const documentById = '/documents/:id';
}

const _kAuthRoutes = {
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.forgotPassword,
};

/// Routes that bypass the auth redirect (splash decides destination itself).
const _kBootRoutes = {
  AppRoutes.splash,
};

/// Transient routes inside a multi-step flow (OTP, reset password, complete
/// phone). They are accessible both unauthenticated (OTP verify) and
/// authenticated (reset password right after verifyOTP creates a session;
/// complete-phone for sessions that landed without phone). The screen
/// itself decides the next destination — the router must not redirect.
const _kTransientAuthRoutes = {
  AppRoutes.otpVerify,
  AppRoutes.resetPassword,
  AppRoutes.completePhone,
};

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge: Supabase auth events → GoRouter refreshListenable. We refresh on
  // every auth event (not just userId changes) because the signup 2FA guard
  // depends on phone_confirmed_at, which mutates without changing userId.
  final authNotifier = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, next) {
    authNotifier.value++;
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Splash handles its own navigation after warm-up; skip guard.
      if (_kBootRoutes.contains(state.matchedLocation)) return null;

      final user = Supabase.instance.client.auth.currentUser;
      final isLoggedIn = user != null;
      final isAuthRoute = _kAuthRoutes.contains(state.matchedLocation);
      final isTransient =
          _kTransientAuthRoutes.contains(state.matchedLocation);

      // Transient routes own their navigation (OTP verify, reset password).
      if (isTransient) return null;

      // Only fully verified users are bounced off auth routes. A logged-in
      // session with phoneConfirmedAt == null is mid-signup (between the
      // signedIn event of signUp and verifyPhoneChangeOtp); the SignUpScreen
      // owns navigation in that window. Detection of "pending OTP at app
      // start / re-login" is async and lives in SplashScreen and LoginScreen
      // via the get_pending_phone() RPC — the SDK does not expose
      // auth.users.phone_change.
      final fullyVerified = isLoggedIn && user.phoneConfirmedAt != null;
      if (fullyVerified && isAuthRoute) return AppRoutes.home;

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.welcome;

      // Session with no verified phone landing on an authenticated route
      // (home, deep link, etc.) — force the phone-capture flow. Auth screens
      // and the transient routes above are already excluded; SignUpScreen
      // owns its own attachPhone flow, and the OTP / reset / complete-phone
      // screens are exempt because they're transient.
      if (isLoggedIn && !fullyVerified && !isAuthRoute) {
        return AppRoutes.completePhone;
      }
      return null;
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
              path: AppRoutes.profileSupport,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: const SupportScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.profileTerms,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: const LegalTextScreen(
                  title: 'TÉRMINOS Y CONDICIONES',
                  body: LegalContent.terms,
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.profilePrivacy,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: const LegalTextScreen(
                  title: 'POLÍTICA DE PRIVACIDAD',
                  body: LegalContent.privacy,
                ),
              ),
            ),
          ]),
        ],
      ),
    ],
  );
});
