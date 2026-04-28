import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

/// Reusable ledger row: leading widget + title/subtitle + amount/return.
/// Used in strategy brand rows and brand investment rows.
class LhotseLedgerRow extends StatefulWidget {
  const LhotseLedgerRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    required this.amount,
    this.returnLabel,
    this.muted = false,
    this.isLast = false,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final double amount;
  final String? returnLabel;
  final bool muted;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  State<LhotseLedgerRow> createState() => _LhotseLedgerRowState();
}

class _LhotseLedgerRowState extends State<LhotseLedgerRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.muted ? AppColors.accentMuted : AppColors.textPrimary;

    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _pressed = false)
          : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          decoration: widget.isLast
              ? null
              : BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading (logo, thumbnail, etc.)
              widget.leading,
              const SizedBox(width: 14),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTypography.bodyEmphasis.copyWith(
                        color: textColor,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle!,
                        style: AppTypography.annotation.copyWith(
                          color: AppColors.accentMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Amount + return
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _eurFormat.format(widget.amount),
                          // EXCEPTION: tabular figures for column-stable amount alignment
                          style: AppTypography.bodyEmphasis.copyWith(
                            color: textColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        TextSpan(
                          text: '€',
                          style: AppTypography.annotation.copyWith(
                            color: textColor,
                            ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.returnLabel != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      widget.returnLabel!,
                      style: AppTypography.annotation.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
