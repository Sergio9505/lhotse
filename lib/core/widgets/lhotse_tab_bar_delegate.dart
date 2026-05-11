import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'lhotse_filter_tab.dart';

/// Public so screens that compose this delegate (e.g. L3 detail screens
/// reporting pinned-header height to `ExtendedNestedScrollView`) can stay in
/// sync with the actual rendered height.
const double kLhotseTabBarHeight = 49.0;

/// Shared pinned tab bar delegate for investment detail screens. Renders the
/// tabs as **content-width left-aligned** `LhotseFilterTab(fullWidth: false)`
/// items driven by the given [TabController], horizontally scrollable when
/// they overflow. Editorial-luxe pattern (Hermès, Sotheby's auction lot
/// detail, Apple Music library subnav, Apple News): the underline matches
/// each tab's text width, gap is consistent, and tab strings are passed in
/// **Title Case / sentence case** by callers — uppercase tracked is reserved
/// for section headers (`INFORMACIÓN`, `PLANO`, etc.), the only graphic
/// anchor per section.
class LhotseTabBarDelegate extends SliverPersistentHeaderDelegate {
  const LhotseTabBarDelegate({
    required this.controller,
    required this.tabs,
  });

  final TabController controller;
  final List<Tab> tabs;

  @override
  double get minExtent => kLhotseTabBarHeight;
  @override
  double get maxExtent => kLhotseTabBarHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, _) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // Respect the content column — first tab aligns with the rest of
          // the screen (title, metrics, lists all sit at lg from the edge).
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (int i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xl),
                LhotseFilterTab(
                  label: tabs[i].text ?? '',
                  isActive: controller.index == i,
                  onTap: () => controller.animateTo(i),
                  editorial: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant LhotseTabBarDelegate oldDelegate) =>
      controller != oldDelegate.controller || tabs != oldDelegate.tabs;
}
