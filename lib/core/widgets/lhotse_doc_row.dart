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
    this.onTap,
    this.onDownload,
  });

  final String name;
  final String date;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;

  @override
  State<LhotseDocRow> createState() => _LhotseDocRowState();
}

class _LhotseDocRowState extends State<LhotseDocRow> {
  bool _pressed = false;

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
                    ),
                    Text(
                      widget.date,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 0.8,
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
