import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pinned `SliverPersistentHeader` delegate that hosts a horizontal filter
/// row (e.g. document category chips). Stays anchored at the top of its
/// scroll context so the underlying list can scroll past while the active
/// filter context remains visible — pattern used by Apple Settings (search
/// + section pills), Apple Mail (folder + filter pills), Apple News
/// (sub-nav).
///
/// The wrapping screen owns the layout/composition of [child]; this
/// delegate only handles the sticky behaviour and the background fill
/// (matches `AppColors.background` so list rows scroll cleanly underneath
/// without a visible seam).
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
