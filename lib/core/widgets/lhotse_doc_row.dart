import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// Reusable document row with press feedback. Tap on the row opens the
/// document in the system viewer (Quick Look on iOS, Intent.ACTION_VIEW on
/// Android) — both expose a native share sheet for download / save / print
/// / mark / share. No inline download button: the wealth-luxe pattern
/// (Apple Files / Apple Mail attachments / Apple Books / JPM Private)
/// trusts the OS viewer to surface secondary actions without duplicating
/// them in the row chrome.
///
/// Layout: `[category icon 18pt] · name + (subtitle)·date · [chevron 16pt]`.
/// The chevron is a tap-affordance hint paralleling `_PurchaseRow` /
/// `_CoinvestmentRow` row chevrons in L2.
class LhotseDocRow extends StatefulWidget {
  const LhotseDocRow({
    super.key,
    required this.name,
    required this.date,
    required this.icon,
    this.subtitle,
    this.onTap,
  });

  final String name;
  final String date;
  final IconData icon;

  /// Optional context line (e.g. project / asset / offering) shown between
  /// `name` and `date`. Used by the search screen to disambiguate docs like
  /// "Memoria del proyecto" that would otherwise be meaningless out of
  /// context.
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  State<LhotseDocRow> createState() => _LhotseDocRowState();
}

class _LhotseDocRowState extends State<LhotseDocRow> {
  bool _pressed = false;

  bool get _hasSubtitle =>
      widget.subtitle != null && widget.subtitle!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap != null;
    return GestureDetector(
      onTapDown: tappable ? (_) => setState(() => _pressed = true) : null,
      onTapUp: tappable ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: tappable ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: AppTypography.bodyReading.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _hasSubtitle
                            ? '${widget.subtitle} · ${widget.date}'
                            : widget.date,
                        style: AppTypography.labelUppercaseSm.copyWith(
                          color: AppColors.accentMuted,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (tappable)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm),
                  child: PhosphorIcon(
                    PhosphorIconsThin.caretRight,
                    size: 16,
                    color: AppColors.accentMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
