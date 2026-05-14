import 'package:flutter/material.dart';

import '../domain/brand_data.dart';
import '../theme/app_theme.dart';
import 'brand_wordmark.dart';

/// Reusable horizontal brand filter row with SVG logos (single-select).
/// The active brand uses a double signal: **full opacity + dot indicator**
/// below the logo. Inactive brands dim to 0.35. With 13+ brands scrollable,
/// the opacity contrast gives an immediate visual anchor and the dot (same
/// pattern as the navbar) reinforces the selection unambiguously — needed
/// because some SVGs render visually small due to internal whitespace.
class LhotseBrandFilterRow extends StatelessWidget {
  const LhotseBrandFilterRow({
    super.key,
    required this.brands,
    required this.selectedBrands,
    required this.onBrandTap,
  });

  final List<BrandData> brands;
  final Set<String> selectedBrands;
  final ValueChanged<String> onBrandTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: brands.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, i) {
          final brand = brands[i];
          final hasSelection = selectedBrands.isNotEmpty;
          final isSelected = selectedBrands.contains(brand.name);
          final double opacity =
              hasSelection ? (isSelected ? 1.0 : 0.35) : 0.6;

          return GestureDetector(
            onTap: () => onBrandTap(brand.name),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: opacity,
                  child: BrandWordmark(
                    brand: brand,
                    size: BrandWordmarkSize.sm,
                    preferDetail: true,
                    // Fixed bounding box calibrated against the adjacent
                    // LhotseFilterChip (also 28pt tall) so wordmarks read as
                    // peer filter accessories, not heroes. BoxFit.contain
                    // scales wide wordmarks down (Nuve 8:1) and lets narrow
                    // ones (Ammaca 2:1) fill the slot. Uniform pitch 112pt
                    // with the AppSpacing.lg separator.
                    containerSize: const Size(88, 28),
                    // Anchor to the bottom of the slot so multi-line tight
                    // SVGs (Myttas, Ammaca — icon-above-text) and single-
                    // line ones (Lacomb & Bos, Nuve) share the same
                    // textual baseline. With center alignment, multi-line
                    // wordmarks rendered with their text in the lower third
                    // while single-line ones sat at the midline → visibly
                    // misaligned baselines across the row.
                    alignment: Alignment.bottomCenter,
                    fallback: Center(
                      child: Text(
                        brand.name[0],
                        style: AppTypography.bodyInput.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.textPrimary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

