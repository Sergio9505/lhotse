import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/data/supabase_provider.dart';
import '../core/domain/asset_data.dart';
import '../core/domain/brand_data.dart';
import '../core/domain/news_item_data.dart';
import '../core/domain/project_data.dart';
import '../features/auth/presentation/login_screen.dart';
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
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/kyc_screen.dart';
import '../features/profile/presentation/legal_text_screen.dart';
import '../features/profile/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/security_screen.dart';
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
  static const profileKyc = '/profile/kyc';
  static const profileNotifications = '/profile/notifications';
  static const profileSecurity = '/profile/security';
  static const profileSupport = '/profile/support';
  static const profileTerms = '/profile/terms';
  static const profilePrivacy = '/profile/privacy';
}

const _kAuthRoutes = {
  AppRoutes.welcome,
  AppRoutes.login,
};

/// Routes that bypass the auth redirect (splash decides destination itself).
const _kBootRoutes = {
  AppRoutes.splash,
};

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge: Riverpod StreamProvider → GoRouter refreshListenable
  final authNotifier = ValueNotifier<AsyncValue<String?>>(const AsyncLoading());
  ref.listen(currentUserIdProvider, (_, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Splash handles its own navigation after warm-up; skip guard.
      if (_kBootRoutes.contains(state.matchedLocation)) return null;

      final authValue = authNotifier.value;

      // Still loading session — don't redirect yet
      if (authValue is AsyncLoading) return null;

      final isLoggedIn = authValue.valueOrNull != null;
      final isAuthRoute = _kAuthRoutes.contains(state.matchedLocation);

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.welcome;
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;
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
              path: AppRoutes.profileKyc,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: const KycScreen(),
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
                child: const SecurityScreen(),
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
