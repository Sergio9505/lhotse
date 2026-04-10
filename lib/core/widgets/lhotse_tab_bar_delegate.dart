import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _kTabBarHeight = 49.0;

/// Shared pinned tab bar delegate for investment detail screens.
/// Fill alignment, full-width indicator, consistent typography.
class LhotseTabBarDelegate extends SliverPersistentHeaderDelegate {
  const LhotseTabBarDelegate({
    required this.controller,
    required this.tabs,
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 4),
  });

  final TabController controller;
  final List<Tab> tabs;
  final EdgeInsetsGeometry labelPadding;

  @override
  double get minExtent => _kTabBarHeight;
  @override
  double get maxExtent => _kTabBarHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: TabBar(
              controller: controller,
              tabAlignment: TabAlignment.fill,
              isScrollable: false,
              labelPadding: labelPadding,
              labelStyle: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
              unselectedLabelStyle: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
              ),
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.accentMuted,
              indicator: const UnderlineTabIndicator(
                borderSide:
                    BorderSide(width: 1.5, color: AppColors.textPrimary),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: tabs,
            ),
          ),
          Container(
            height: 0.5,
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant LhotseTabBarDelegate oldDelegate) =>
      controller != oldDelegate.controller;
}
