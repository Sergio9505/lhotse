import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/brands/presentation/brand_detail_screen.dart';
import '../features/brands/presentation/brands_screen.dart';
import '../features/home/presentation/all_news_screen.dart';
import '../features/home/presentation/all_projects_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/project_detail_screen.dart';
import '../features/investments/presentation/brand_investments_screen.dart';
import '../features/investments/presentation/investment_detail_screen.dart';
import '../features/investments/presentation/investments_screen.dart';
import '../features/investments/presentation/opportunities_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
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
  static const home = '/';
  static const projects = '/projects';
  static const news = '/news';
  static const projectDetail = '/projects/:id';
  static const brands = '/brands';
  static const brandDetail = '/brands/:id';
  static const search = '/search';
  static const investments = '/investments';
  static const brandInvestments = '/investments/brand/:brandName';
  static const investmentDetail = '/investments/detail/:id';
  static const opportunities = '/investments/opportunities';
  static const profile = '/profile';
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
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
                final brandName = state.pathParameters['brandName']!;
                return _fadePage(
                  key: state.pageKey,
                  child: BrandInvestmentsScreen(
                      brandName: Uri.decodeComponent(brandName)),
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
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ]),
        ],
      ),
    ],
  );
});
