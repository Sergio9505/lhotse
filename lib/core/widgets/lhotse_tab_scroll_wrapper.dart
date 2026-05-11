import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Body wrapper for L3 detail screen tabs.
///
/// Renders [child] inside a `SingleChildScrollView` with bottom padding that
/// respects the device safe area + a standard breathing room of `lg`.
/// Used as each direct child of the `TabBarView` body inside an
/// `ExtendedNestedScrollView` — the package handles per-tab scroll position
/// preservation, so this widget only needs to provide the Scrollable +
/// padding contract.
class LhotseTabScrollWrapper extends StatelessWidget {
  const LhotseTabScrollWrapper({
    super.key,
    required this.child,
    required this.bottomPadding,
  });

  final Widget child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding + AppSpacing.lg),
      child: child,
    );
  }
}
