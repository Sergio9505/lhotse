import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'lhotse_filter_tab.dart';

const _kTabBarHeight = 49.0;

/// Shared pinned tab bar delegate for investment detail screens. Renders the
/// tabs as **full-width peer-equal** `LhotseFilterTab(fullWidth: true)` cells
/// driven by the given [TabController]. Fintech-premium pattern (Apple
/// Wallet, Revolut, BBVA Premium) — each tab gets an equal cell and the
/// active underline spans its full width, giving a clear "this section is
/// active" signal.
class LhotseTabBarDelegate extends SliverPersistentHeaderDelegate {
  const LhotseTabBarDelegate({
    required this.controller,
    required this.tabs,
  });

  final TabController controller;
  final List<Tab> tabs;

  @override
  double get minExtent => _kTabBarHeight;
  @override
  double get maxExtent => _kTabBarHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, _) => Padding(
          // Respect the content column — underlines align with the rest of
          // the screen (title, metrics, lists all sit at lg from the edge).
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (int i = 0; i < tabs.length; i++)
                Expanded(
                  child: LhotseFilterTab(
                    label: tabs[i].text ?? '',
                    isActive: controller.index == i,
                    onTap: () => controller.animateTo(i),
                    fullWidth: true,
                  ),
                ),
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
