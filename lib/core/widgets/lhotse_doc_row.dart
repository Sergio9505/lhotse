import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// Reusable document row with press feedback.
/// Tap row = preview, download icon = download action.
class LhotseDocRow extends StatefulWidget {
  const LhotseDocRow({
    super.key,
    required this.name,
    required this.date,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.onDownload,
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
  final VoidCallback? onDownload;

  @override
  State<LhotseDocRow> createState() => _LhotseDocRowState();
}

class _LhotseDocRowState extends State<LhotseDocRow> {
  bool _pressed = false;

  bool get _hasSubtitle =>
      widget.subtitle != null && widget.subtitle!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
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
                      style: AppTypography.bodyMedium.copyWith(
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
                        style: AppTypography.caption.copyWith(
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
              GestureDetector(
                onTap: widget.onDownload,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: PhosphorIcon(PhosphorIconsThin.downloadSimple,
                      size: 16, color: AppColors.accentMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
