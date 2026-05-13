import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/brand_data.dart';
import '../theme/app_theme.dart';

enum BrandWordmarkSize { xs, sm, md, lg }

/// Renders a brand wordmark from `brand.logoAsset` (SVG) at a canonical
/// optical height. Width is intentionally left free so the unified viewBox
/// ratio determines it via `BoxFit.contain`. When the chosen asset is null,
/// renders `fallback` if provided, otherwise the brand name uppercase.
///
/// `preferDetail: true` reads `logoAssetDetail` (tight-cropped variant) with
/// transparent fallback to `logoAsset` when the detail variant isn't uploaded.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    required this.brand,
    this.size = BrandWordmarkSize.sm,
    this.color,
    this.fallback,
    this.preferDetail = false,
  });

  final BrandData brand;
  final BrandWordmarkSize size;
  final Color? color;
  final Widget? fallback;
  final bool preferDetail;

  double get _height => switch (size) {
        BrandWordmarkSize.xs => 24,
        BrandWordmarkSize.sm => 32,
        BrandWordmarkSize.md => 40,
        BrandWordmarkSize.lg => 64,
      };

  @override
  Widget build(BuildContext context) {
    final logo = preferDetail
        ? (brand.logoAssetDetail ?? brand.logoAsset)
        : brand.logoAsset;
    final tint = color ?? AppColors.textPrimary;

    if (logo == null) {
      return fallback ??
          Text(
            brand.name.toUpperCase(),
            style: AppTypography.titleUppercase.copyWith(color: tint),
          );
    }

    final filter = ColorFilter.mode(tint, BlendMode.srcIn);
    return SizedBox(
      height: _height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          height: _height,
          child: logo.startsWith('http')
              ? SvgPicture.network(logo, fit: BoxFit.contain, colorFilter: filter)
              : SvgPicture.asset(logo, fit: BoxFit.contain, colorFilter: filter),
        ),
      ),
    );
  }
}
