import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../domain/asset_info.dart';
import '../theme/app_theme.dart';

/// Reusable key-value list with dividers.
/// Used for asset info, economic analysis, and similar data displays.
class LhotseKeyValueList extends StatelessWidget {
  const LhotseKeyValueList({
    super.key,
    required this.entries,
    this.highlightLast = false,
  });

  final List<AssetInfoEntry> entries;

  /// Makes the last row bold with a thicker divider (e.g. "Gastos totales").
  final bool highlightLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: entries.indexed.map((entry) {
          final i = entry.$1;
          final e = entry.$2;
          final isLast = i == entries.length - 1;
          final isBold = isLast && highlightLast;

          return Column(
            children: [
              if (i > 0)
                Container(
                  height: isBold ? 1 : 0.5,
                  color: AppColors.textPrimary
                      .withValues(alpha: isBold ? 0.2 : 0.08),
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: isBold ? 14.0 : 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        e.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accentMuted,
                          fontWeight:
                              isBold ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (e.copyable)
                      InkWell(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: e.value));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${e.label} copiada'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              e.value,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: isBold
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Icon(
                                PhosphorIconsThin.copy,
                                size: 18,
                                color: AppColors.accentMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        e.value,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight:
                              isBold ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
