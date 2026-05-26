import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/project_phase.dart';
import '../theme/app_theme.dart';

/// Editorial timeline used in both the L1 commercial project detail (Avance
/// tab) and the L3 coinversion detail (Avance tab). Renders a single-row
/// track of phase nodes with month labels, the active node pulsing.
///
/// API is contract-agnostic — phases come from `project_phases` keyed by
/// `project_id`, surfaced via `projectPhasesProvider`.
class LhotseProjectTimeline extends StatelessWidget {
  const LhotseProjectTimeline({
    super.key,
    required this.phases,
    required this.currentIndex,
  });

  final List<ProjectPhase> phases;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          SizedBox(
            height: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < phases.length; i++) ...[
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= currentIndex
                            ? AppColors.primary
                            : AppColors.textPrimary
                                .withValues(alpha: 0.08),
                      ),
                    ),
                  if (i == currentIndex)
                    _PulsingNode(size: 10)
                  else
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i < currentIndex
                            ? AppColors.primary
                            : Colors.transparent,
                        border: i > currentIndex
                            ? Border.all(
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.15),
                                width: 1.5)
                            : null,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: phases.indexed.map((entry) {
              final i = entry.$1;
              final phase = entry.$2;
              final isCurrent = i == currentIndex;
              final isPast = i < currentIndex;
              final month =
                  DateFormat('MM/yy').format(phase.startDate).toUpperCase();
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      phase.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: isCurrent
                            ? AppColors.textPrimary
                            : isPast
                                ? AppColors.accentMuted
                                : AppColors.textPrimary
                                    .withValues(alpha: 0.25),
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w400,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (isCurrent && phase.title != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        phase.title!,
                        textAlign: TextAlign.center,
                        style: AppTypography.annotation.copyWith(
                          color: AppColors.accentMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      month,
                      textAlign: TextAlign.center,
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: isCurrent
                            ? AppColors.accentMuted
                            : AppColors.textPrimary
                                .withValues(alpha: 0.2),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PulsingNode extends StatefulWidget {
  const _PulsingNode({required this.size});
  final double size;
  @override
  State<_PulsingNode> createState() => _PulsingNodeState();
}

class _PulsingNodeState extends State<_PulsingNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size + 8,
      height: widget.size + 8,
      child: Center(
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
