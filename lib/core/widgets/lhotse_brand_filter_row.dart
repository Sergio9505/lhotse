import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/mock/mock_brands.dart';
import '../theme/app_theme.dart';

/// Reusable horizontal brand filter row with SVG logos and multi-select.
class LhotseBrandFilterRow extends StatelessWidget {
  const LhotseBrandFilterRow({
    super.key,
    required this.selectedBrands,
    required this.onBrandTap,
    required this.onClear,
  });

  final Set<String> selectedBrands;
  final ValueChanged<String> onBrandTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedBrands.isNotEmpty;
    final itemCount = mockBrands.length + (hasSelection ? 1 : 0);

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, i) {
          if (hasSelection && i == mockBrands.length) {
            return GestureDetector(
              onTap: onClear,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 32,
                    child: PhosphorIcon(
                      PhosphorIconsThin.x,
                      size: 16,
                      color: AppColors.accentMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'LIMPIAR',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.accentMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            );
          }

          final brand = mockBrands[i];
          final isSelected = selectedBrands.contains(brand.name);
          final double opacity =
              hasSelection ? (isSelected ? 1.0 : 0.35) : 0.6;

          return GestureDetector(
            onTap: () => onBrandTap(brand.name),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: opacity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (brand.logoAsset != null)
                    SvgPicture.asset(
                      brand.logoAsset!,
                      height: 32,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textPrimary,
                        BlendMode.srcIn,
                      ),
                    )
                  else
                    Text(
                      brand.name[0],
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    brand.name.toUpperCase(),
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
