import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Premium pull-to-refresh with a thin horizontal line indicator.
/// - Pull phase: line fills left→right based on progress
/// - Threshold reached: full line, brighter
/// - Refreshing: indeterminate sweep animation
/// - Done: fades out
class LhotsePullToRefresh extends StatefulWidget {
  const LhotsePullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.threshold = 72.0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final double threshold;

  @override
  State<LhotsePullToRefresh> createState() => _LhotsePullToRefreshState();
}

class _LhotsePullToRefreshState extends State<LhotsePullToRefresh>
    with SingleTickerProviderStateMixin {
  static const _kLineH = 1.0;

  double _pullExtent = 0;
  bool _refreshing = false;
  bool _triggered = false;

  late AnimationController _shimmer;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _shimmerAnim = CurvedAnimation(parent: _shimmer, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  bool _onNotification(ScrollNotification n) {
    if (_refreshing) return false;

    if (n is OverscrollNotification &&
        n.overscroll < 0 &&
        n.metrics.extentBefore == 0) {
      // Dampen: half the raw overscroll so it feels controlled
      setState(() {
        _pullExtent = (_pullExtent - n.overscroll * 0.5)
            .clamp(0, widget.threshold * 1.3);
      });
    } else if (n is ScrollUpdateNotification && _pullExtent > 0) {
      setState(() {
        _pullExtent = (_pullExtent - (n.scrollDelta ?? 0))
            .clamp(0.0, widget.threshold * 1.3);
      });
    } else if (n is ScrollEndNotification && !_triggered) {
      if (_pullExtent >= widget.threshold) {
        _doRefresh();
      } else {
        setState(() => _pullExtent = 0);
      }
    }
    return false;
  }

  Future<void> _doRefresh() async {
    setState(() {
      _refreshing = true;
      _triggered = true;
    });
    _shimmer.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _shimmer.stop();
        _shimmer.reset();
        setState(() {
          _refreshing = false;
          _triggered = false;
          _pullExtent = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_pullExtent / widget.threshold).clamp(0.0, 1.0);
    final visible = _pullExtent > 1 || _refreshing;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onNotification,
          child: widget.child,
        ),

        // Thin indicator line at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _kLineH,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: visible ? 1.0 : 0.0,
            child: _refreshing
                ? AnimatedBuilder(
                    animation: _shimmerAnim,
                    builder: (_, __) => CustomPaint(
                      painter: _SweepPainter(_shimmer.value),
                    ),
                  )
                : _FillLine(progress: progress),
          ),
        ),
      ],
    );
  }
}

// ── Fill line — fills left to right based on pull progress ───────────────────

class _FillLine extends StatelessWidget {
  const _FillLine({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => Stack(
        children: [
          // Track
          Container(color: AppColors.textPrimary.withValues(alpha: 0.08)),
          // Fill
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: constraints.maxWidth * progress,
            color: progress >= 1.0
                ? AppColors.textPrimary
                : AppColors.textPrimary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

// ── Sweep painter — shimmer animation during refresh ─────────────────────────

class _SweepPainter extends CustomPainter {
  const _SweepPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Sweep a bright spot left to right repeatedly
    final sweepX = size.width * t;
    final sweepW = size.width * 0.35;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.textPrimary.withValues(alpha: 0.08),
          AppColors.textPrimary.withValues(alpha: 0.15),
          AppColors.textPrimary,
          AppColors.textPrimary.withValues(alpha: 0.15),
          AppColors.textPrimary.withValues(alpha: 0.08),
        ],
        stops: [
          ((sweepX - sweepW * 0.5) / size.width).clamp(0, 1),
          ((sweepX - sweepW * 0.2) / size.width).clamp(0, 1),
          (sweepX / size.width).clamp(0, 1),
          ((sweepX + sweepW * 0.2) / size.width).clamp(0, 1),
          ((sweepX + sweepW * 0.5) / size.width).clamp(0, 1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_SweepPainter old) => old.t != t;
}
