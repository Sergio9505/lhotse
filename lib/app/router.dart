import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/data/supabase_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/brands/presentation/brand_detail_screen.dart';
import '../features/brands/presentation/brands_screen.dart';
import '../features/home/presentation/all_news_screen.dart';
import '../features/home/presentation/news_detail_screen.dart';
import '../features/home/presentation/all_projects_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/project_detail_screen.dart';
import '../features/investments/domain/completed_contract_data.dart';
import '../features/investments/domain/coinvestment_contract_data.dart';
import '../features/investments/domain/purchase_contract_data.dart';
import '../features/investments/presentation/brand_investments_screen.dart';
import '../features/investments/presentation/coinversion_detail_screen.dart';
import '../features/investments/presentation/direct_purchase_detail_screen.dart';
import '../features/investments/presentation/completed_detail_screen.dart';
import '../features/investments/presentation/investment_detail_screen.dart';
import '../features/investments/presentation/investments_screen.dart';
import '../features/investments/presentation/opportunities_screen.dart';
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
  // Auth
  static const welcome = '/welcome';
  static const login = '/login';
  // Main app
  static const home = '/';
  static const projects = '/projects';
  static const news = '/news';
  static const newsDetail = '/news/:id';
  static const projectDetail = '/projects/:id';
  static const brands = '/brands';
  static const brandDetail = '/brands/:id';
  static const search = '/search';
  static const investments = '/investments';
  static const brandInvestments = '/investments/brand/:brandId';
  static const investmentDetail = '/investments/detail/:id';
  static const purchaseDetail = '/investments/detail/purchase/:id';
  static const coinvestmentDetail = '/investments/detail/coinvestment/:id';
  static const completedPurchaseDetail = '/investments/detail/completed/purchase/:id';
  static const completedCoinvestmentDetail = '/investments/detail/completed/coinvestment/:id';
  static const opportunities = '/investments/opportunities';
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

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge: Riverpod StreamProvider → GoRouter refreshListenable
  final authNotifier = ValueNotifier<AsyncValue<String?>>(const AsyncLoading());
  ref.listen(currentUserIdProvider, (_, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: authNotifier,
    redirect: (context, state) {
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
              path: AppRoutes.news,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: const AllNewsScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.newsDetail,
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                return _fadePage(
                  key: state.pageKey,
                  child: NewsDetailScreen(newsId: id),
                );
              },
            ),
            GoRoute(
              path: AppRoutes.projects,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AllProjectsScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.projectDetail,
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                return _fadePage(
                  key: state.pageKey,
                  child: ProjectDetailScreen(projectId: id),
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
                return _fadePage(
                  key: state.pageKey,
                  child: BrandDetailScreen(brandId: id),
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
                return _fadePage(
                  key: state.pageKey,
                  child: BrandInvestmentsScreen(brandId: brandId),
                );
              },
            ),
            GoRoute(
              path: AppRoutes.opportunities,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: const OpportunitiesScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.investmentDetail,
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                return _fadePage(
                  key: state.pageKey,
                  child: InvestmentDetailScreen(investmentId: id),
                );
              },
            ),
            GoRoute(
              path: AppRoutes.purchaseDetail,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: DirectPurchaseDetailScreen(
                  contractId: state.pathParameters['id']!,
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.coinvestmentDetail,
              pageBuilder: (context, state) => _fadePage(
                key: state.pageKey,
                child: CoinversionDetailScreen(
                  contract: state.extra as CoinvestmentContractData,
                ),
              ),
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
