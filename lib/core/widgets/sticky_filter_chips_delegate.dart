import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pinned `SliverPersistentHeader` delegate for filter chips that should
/// stay anchored at the top of the outer scroll context (e.g., the
/// `headerSliverBuilder` of a `NestedScrollView`). Used as a sub-nav band
/// directly below the section tabs — chips remain visible while doc rows
/// scroll past underneath.
///
/// The chips are tab-specific so the screen wraps this in an `if` clause
/// inside `headerSliverBuilder` and rebuilds when the active tab changes
/// (typically via a `TabController` listener that calls `setState`).
///
/// Pattern reference: iOS Settings (search + sticky pills), Apple News
/// (top tabs + sub-nav pinned + content scroll).
class StickyFilterChipsDelegate extends SliverPersistentHeaderDelegate {
  const StickyFilterChipsDelegate({
    required this.child,
    this.height = 48,
  });

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant StickyFilterChipsDelegate oldDelegate) =>
      child != oldDelegate.child || height != oldDelegate.height;
}
