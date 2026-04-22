import 'dart:async';

import 'package:flutter/material.dart';

/// Filter bar that hides itself while the user is actively scrolling and
/// restores itself automatically after a brief idle moment (default 2s).
/// Inspired by premium reading apps (Apple Stocks, NYT) where the secondary
/// chrome yields to content during scroll and returns when the user pauses.
///
/// Nothing is shown in the collapsed state — the primary navigation tabs
/// above this widget already communicate the active section, so a textual
/// pill would be redundant. The transition itself (gracefully sliding away)
/// is the affordance.
class ScrollAwareFilterBar extends StatefulWidget {
  const ScrollAwareFilterBar({
    super.key,
    required this.scrollController,
    required this.expanded,
    this.idleDelay = const Duration(seconds: 2),
    this.scrollThreshold = 6.0,
  });

  /// The fully-rendered filter bar (tabs/chips + icons). Height should be
  /// stable across builds so the animated transition looks clean.
  final Widget expanded;

  final ScrollController scrollController;
  final Duration idleDelay;

  /// Minimum downward scroll delta (in pts) needed to trigger a collapse.
  /// Filters tiny unintentional movements.
  final double scrollThreshold;

  @override
  State<ScrollAwareFilterBar> createState() => _ScrollAwareFilterBarState();
}

class _ScrollAwareFilterBarState extends State<ScrollAwareFilterBar> {
  bool _collapsed = false;
  Timer? _idleTimer;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _idleTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController.offset;
    final delta = offset - _lastOffset;
    _lastOffset = offset;

    // Only collapse when actively scrolling DOWN past the threshold. Never
    // collapse when we're still above the top (offset ≤ 0) so the first view
    // of the screen always shows the full filter bar.
    if (offset > 0 && delta > widget.scrollThreshold && !_collapsed) {
      setState(() => _collapsed = true);
    }

    // Any scroll activity (up or down) resets the idle timer.
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.idleDelay, () {
      if (mounted && _collapsed) {
        setState(() => _collapsed = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _collapsed
            ? const SizedBox.shrink(key: ValueKey('collapsed'))
            : KeyedSubtree(
                key: const ValueKey('expanded'),
                child: widget.expanded,
              ),
      ),
    );
  }
}
