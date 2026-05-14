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
      height: 64,
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
                  child: SizedBox(
                    height: 36,
                    child: Center(
                      child: BrandWordmark(
                        brand: brand,
                        size: BrandWordmarkSize.sm,
                        preferDetail: true,
                        fallback: Text(
                          brand.name[0],
                          style: AppTypography.bodyInput.copyWith(
                            color: AppColors.textPrimary,
                          ),
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

