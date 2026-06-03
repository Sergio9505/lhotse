import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/brand_data.dart';
import '../theme/app_theme.dart';

/// Per-brand optical calibration: render height for each brand's wordmark so
/// the **text** reads at the same optical weight across heterogeneous logos.
/// Stacked lockups (symbol over text, e.g. Myttas) render taller so their text
/// matches single-line wordmarks (e.g. Vellte). Brands not listed use the
/// default. Tune by eye; move to a `brands` column if the catalog grows.
const _defaultWordmarkHeight = 32.0; // single-line target (Vellte + future)
const _wordmarkHeightByBrand = <String, double>{
  // Only STACKED logos (symbol over text) need an entry — a small bump so
  // their TEXT matches the single-line wordmarks (bottom-aligned). NOT a big
  // multiplier: these logos are mostly text, so the delta only compensates
  // the small symbol on top. Single-line brands use the default automatically;
  // can't auto-detect "stacked" from the SVG, so stacked ones are listed here.
  'Myttas': 40.0,
  'Ammaca': 40.0,
};

/// Reusable horizontal brand filter row (single-select), rendering each
/// brand's **wordmark** (`logoAsset`, mono `srcIn` → `textPrimary`) at a
/// per-brand calibrated height so heterogeneous logos read balanced. The row
/// is **left-aligned** (consistent with the app) and scrolls horizontally.
/// Selection: full opacity + dot below; inactive dims to 0.35 (0.6 when
/// nothing is selected).
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

  static const _tint =
      ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn);

  double _heightFor(BrandData b) =>
      _wordmarkHeightByBrand[b.name] ?? _defaultWordmarkHeight;

  @override
  Widget build(BuildContext context) {
    final maxHeight = brands.fold<double>(
      _defaultWordmarkHeight,
      (acc, b) => _heightFor(b) > acc ? _heightFor(b) : acc,
    );
    // wordmark (bottom-aligned) + gap(6) + dot(4) + 2px slack.
    final rowHeight = maxHeight + 12;

    // Left-aligned (the whole app aligns left) — with few brands there's empty
    // space on the right, which reads as "scroll for more", consistent with
    // the app. No centering.
    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: brands.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, i) => _BrandCell(
          brand: brands[i],
          height: _heightFor(brands[i]),
          rowHeight: rowHeight,
          hasSelection: selectedBrands.isNotEmpty,
          isSelected: selectedBrands.contains(brands[i].name),
          onTap: () => onBrandTap(brands[i].name),
        ),
      ),
    );
  }
}

class _BrandCell extends StatelessWidget {
  const _BrandCell({
    required this.brand,
    required this.height,
    required this.rowHeight,
    required this.hasSelection,
    required this.isSelected,
    required this.onTap,
  });

  final BrandData brand;
  final double height;
  final double rowHeight;
  final bool hasSelection;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opacity = hasSelection ? (isSelected ? 1.0 : 0.35) : 0.6;
    return GestureDetector(
      // opaque + full row height → whole cell is tappable despite SVG
      // transparency (the "logo sometimes doesn't respond" bug).
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: rowHeight,
        child: Column(
          // Bottom-align so wordmarks of different calibrated heights share a
          // baseline and the selection dot sits on a common line.
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: opacity,
              child: _wordmark(),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wordmark() {
    // Full variant (`logoAsset`), NOT the tight `logoAssetDetail`: the tight
    // crop removes vertical whitespace too, so single-line wordmarks (Vellte)
    // get an extreme aspect ratio and explode in width at a fixed height. The
    // full variant shares consistent vertical framing across brands, so the
    // per-brand calibrated height balances the text. Trade-off: the full SVG
    // carries some internal left padding (an asset-level concern).
    final logo = brand.logoAsset;
    if (logo == null || logo.isEmpty) {
      return Text(
        brand.name.toUpperCase(),
        style: AppTypography.labelUppercaseSm.copyWith(
          color: AppColors.textPrimary,
        ),
      );
    }
    // Fixed height, intrinsic width (no width cap → wide wordmarks aren't
    // shrunk). Mono `srcIn` like BrandWordmark's default tint.
    return logo.startsWith('http')
        ? SvgPicture.network(
            logo,
            height: height,
            fit: BoxFit.contain,
            colorFilter: LhotseBrandFilterRow._tint,
          )
        : SvgPicture.asset(
            logo,
            height: height,
            fit: BoxFit.contain,
            colorFilter: LhotseBrandFilterRow._tint,
          );
  }
}
