import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/brand_data.dart';
import '../theme/app_theme.dart';

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
                  child: SizedBox(
                    width: 80,
                    height: 32,
                    child: Center(child: _BrandLogo(brand: brand)),
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

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.brand});
  final BrandData brand;

  static const _filter = ColorFilter.mode(
    AppColors.textPrimary,
    BlendMode.srcIn,
  );

  @override
  Widget build(BuildContext context) {
    final logo = brand.logoAsset;
    if (logo == null) {
      return Text(
        brand.name[0],
        style: AppTypography.titleUppercase.copyWith(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
      );
    }
    return SizedBox(
      width: 56,
      height: 24,
      child: logo.startsWith('http')
          ? SvgPicture.network(
              logo,
              fit: BoxFit.contain,
              colorFilter: _filter,
            )
          : SvgPicture.asset(
              logo,
              fit: BoxFit.contain,
              colorFilter: _filter,
            ),
    );
  }
}
