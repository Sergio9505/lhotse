import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/project_phase.dart';
import '../theme/app_theme.dart';

/// Editorial timeline used in both the L1 commercial project detail (Avance
/// tab) and the L3 coinversion detail (Avance tab). Renders a single-row
/// track of phase nodes with month labels, the active node pulsing, plus a
/// full-width caption block below showing the selected phase's name +
/// description (defaults to the active phase; tap any phase to switch).
///
/// Alignment: nodes are evenly spaced edge-to-edge by fraction (`i/(N-1)`), so
/// the track honours the page padding (first node at the left edge, last at the
/// right). Each label is positioned by the same fraction and centred on its node
/// (`FractionalTranslation`), with the first/last clamped to the edge — so every
/// label sits under its node, incl. the first and last. The connecting line runs
/// between node edges (inset by `nodeGap`), never through the hollow nodes.
///
/// API is contract-agnostic — phases come from `project_phases` keyed by
/// `project_id`, surfaced via `projectPhasesProvider`.
class LhotseProjectTimeline extends StatefulWidget {
  const LhotseProjectTimeline({
    super.key,
    required this.phases,
    required this.currentIndex,
  });

  final List<ProjectPhase> phases;
  final int currentIndex;

  @override
  State<LhotseProjectTimeline> createState() => _LhotseProjectTimelineState();
}

class _LhotseProjectTimelineState extends State<LhotseProjectTimeline> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentIndex.clamp(0, _maxIndex);
  }

  @override
  void didUpdateWidget(LhotseProjectTimeline old) {
    super.didUpdateWidget(old);
    // Re-sync the selection to the active phase when the data changes (e.g. the
    // phase list or current index updates after a provider refresh).
    if (old.currentIndex != widget.currentIndex ||
        old.phases.length != widget.phases.length) {
      _selected = widget.currentIndex.clamp(0, _maxIndex);
    }
  }

  int get _maxIndex => widget.phases.isEmpty ? 0 : widget.phases.length - 1;

  @override
  Widget build(BuildContext context) {
    final phases = widget.phases;
    if (phases.isEmpty) return const SizedBox.shrink();
    final currentIndex = widget.currentIndex;
    final lastIndex = phases.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Track: nodes evenly spaced edge-to-edge; labels centred on each
          //    node by fraction (ends clamped to the edge) so the track honours
          //    the page padding AND every label sits under its node. ──
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              // Inset node centres by their radius so the first/last node sit
              // fully inside (edge ~ at the content edge), not clipped in half.
              const inset = 6.0;
              final usable = w - 2 * inset;
              double cx(int i) =>
                  inset +
                  (lastIndex == 0 ? usable / 2 : i / lastIndex * usable);

              // Gap left around each node so the line connects between node
              // edges, never crossing the hollow (future) node centres.
              const nodeGap = 7.0;

              return Stack(
                children: [
                  Column(
                    children: [
                      // Nodes + connecting line. Clip.none so the active node's
                      // pulse (×1.4) at the edges is never cut.
                      SizedBox(
                        width: w,
                        height: 20,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (int s = 0; s < lastIndex; s++)
                              Positioned(
                                left: cx(s) + nodeGap,
                                width: (cx(s + 1) - cx(s) - 2 * nodeGap).clamp(
                                  0.0,
                                  double.infinity,
                                ),
                                top: 9,
                                height: 2,
                                child: ColoredBox(
                                  color: s < currentIndex
                                      ? AppColors.primary
                                      : AppColors.textPrimary.withValues(
                                          alpha: 0.08,
                                        ),
                                ),
                              ),
                            for (int i = 0; i < phases.length; i++)
                              Positioned(
                                left: cx(i) - 10,
                                top: 0,
                                width: 20,
                                height: 20,
                                child: Center(
                                  child: _Node(
                                    index: i,
                                    currentIndex: currentIndex,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Labels positioned by fraction under each node.
                      _LabelLayer(
                        width: w,
                        phases: phases,
                        currentIndex: currentIndex,
                        selectedIndex: _selected,
                        cx: cx,
                      ),
                    ],
                  ),
                  // Tap layer: equal-width transparent columns over the whole
                  // track so tapping anywhere in a phase's band selects it.
                  Positioned.fill(
                    child: Row(
                      children: [
                        for (int i = 0; i < phases.length; i++)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _selected = i),
                              child: const SizedBox.expand(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Detail caption for the selected phase ──
          _PhaseDetail(phase: phases[_selected]),
        ],
      ),
    );
  }
}

/// Lays the phase labels out by fraction: each centred on its node (`cx`),
/// with the first pinned to the left edge and the last to the right edge so the
/// track honours the page padding. Height is set by an invisible sizer label so
/// it survives Dynamic Type.
class _LabelLayer extends StatelessWidget {
  const _LabelLayer({
    required this.width,
    required this.phases,
    required this.currentIndex,
    required this.selectedIndex,
    required this.cx,
  });

  final double width;
  final List<ProjectPhase> phases;
  final int currentIndex;
  final int selectedIndex;
  final double Function(int) cx;

  @override
  Widget build(BuildContext context) {
    final lastIndex = phases.length - 1;
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          // Invisible sizer — gives the Stack its height (labels are uniform).
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: _PhaseLabel(
              phase: phases.first,
              index: 0,
              currentIndex: currentIndex,
              isSelected: false,
              align: CrossAxisAlignment.center,
              textAlign: TextAlign.center,
            ),
          ),
          for (int i = 0; i < phases.length; i++)
            _positioned(
              i: i,
              lastIndex: lastIndex,
              child: _PhaseLabel(
                phase: phases[i],
                index: i,
                currentIndex: currentIndex,
                isSelected: i == selectedIndex,
                align: i == 0
                    ? CrossAxisAlignment.start
                    : i == lastIndex
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.center,
                textAlign: i == 0
                    ? TextAlign.left
                    : i == lastIndex
                    ? TextAlign.right
                    : TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _positioned({
    required int i,
    required int lastIndex,
    required Widget child,
  }) {
    if (i == 0) return Positioned(left: 0, top: 0, child: child);
    if (i == lastIndex) return Positioned(right: 0, top: 0, child: child);
    // Centre the label on the node without measuring its width.
    return Positioned(
      left: cx(i),
      top: 0,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: child,
      ),
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  const _PhaseLabel({
    required this.phase,
    required this.index,
    required this.currentIndex,
    required this.isSelected,
    required this.align,
    required this.textAlign,
  });

  final ProjectPhase phase;
  final int index;
  final int currentIndex;
  final bool isSelected;
  final CrossAxisAlignment align;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final isCurrent = index == currentIndex;
    final isPast = index < currentIndex;
    final month = DateFormat('MM/yy').format(phase.startDate).toUpperCase();

    final nameColor = isPast
        ? AppColors.accentMuted
        : isCurrent
        ? AppColors.textPrimary
        : AppColors.textPrimary.withValues(alpha: 0.25);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Text(
          phase.name.toUpperCase(),
          textAlign: textAlign,
          style: AppTypography.labelUppercaseSm.copyWith(
            color: isSelected ? AppColors.textPrimary : nameColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          month,
          textAlign: textAlign,
          style: AppTypography.labelUppercaseSm.copyWith(
            color: isCurrent || isSelected
                ? AppColors.accentMuted
                : AppColors.textPrimary.withValues(alpha: 0.2),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.index, required this.currentIndex});

  final int index;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    if (index == currentIndex) return const _PulsingNode(size: 10);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: index < currentIndex ? AppColors.primary : Colors.transparent,
        border: index > currentIndex
            ? Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.15),
                width: 1.5,
              )
            : null,
      ),
    );
  }
}

/// Full-width caption for the selected phase: name (+ title) + description.
/// Hidden entirely when the phase carries neither a title nor a description.
class _PhaseDetail extends StatelessWidget {
  const _PhaseDetail({required this.phase});

  final ProjectPhase phase;

  @override
  Widget build(BuildContext context) {
    final title = phase.title;
    final description = phase.description;
    final hasTitle = title != null && title.isNotEmpty;
    final hasDescription = description != null && description.isNotEmpty;
    if (!hasTitle && !hasDescription) return const SizedBox.shrink();

    final header = hasTitle
        ? '${phase.name.toUpperCase()}  ·  $title'
        : phase.name.toUpperCase();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Container(
        key: ValueKey('${phase.name}-$description'),
        width: double.infinity,
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: AppTypography.labelUppercaseMd.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 1.0,
              ),
            ),
            if (hasDescription) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: AppTypography.annotationParagraph.copyWith(
                  color: AppColors.accentMuted,
                ),
              ),
            ],
          ],
        ),
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
    _scale = Tween(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
          builder: (context, child) =>
              Transform.scale(scale: _scale.value, child: child),
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
