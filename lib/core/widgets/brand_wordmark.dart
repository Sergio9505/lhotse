import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/brand_data.dart';
import '../theme/app_theme.dart';

enum BrandWordmarkSize { xs, sm, md, lg }

/// Renders a brand wordmark from `brand.logoAsset` (SVG).
///
/// For `xs` / `sm` the widget sizes to the SVG's intrinsic width at the
/// canonical height — the parent context (filter row slot, grid card) provides
/// its own uniform bounding box.
///
/// For `md` / `lg` (detail screens) the widget renders inside a fixed-size
/// container with `BoxFit.contain`, so every brand shares the same bounding
/// box regardless of intrinsic aspect ratio.
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
    this.alignment = Alignment.center,
  });

  final BrandData brand;
  final BrandWordmarkSize size;
  final Color? color;
  final Widget? fallback;
  final bool preferDetail;
  final AlignmentGeometry alignment;

  double get _height => switch (size) {
        BrandWordmarkSize.xs => 24,
        BrandWordmarkSize.sm => 36,
        BrandWordmarkSize.md => 28,
        BrandWordmarkSize.lg => 48,
      };

  Size? get _containerSize => switch (size) {
        BrandWordmarkSize.xs => null,
        BrandWordmarkSize.sm => null,
        BrandWordmarkSize.md => const Size(140, 28),
        BrandWordmarkSize.lg => const Size(240, 56),
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
    final container = _containerSize;

    if (container == null) {
      return logo.startsWith('http')
          ? SvgPicture.network(
              logo,
              height: _height,
              fit: BoxFit.contain,
              colorFilter: filter,
            )
          : SvgPicture.asset(
              logo,
              height: _height,
              fit: BoxFit.contain,
              colorFilter: filter,
            );
    }

    return SizedBox.fromSize(
      size: container,
      child: logo.startsWith('http')
          ? SvgPicture.network(
              logo,
              fit: BoxFit.contain,
              alignment: alignment,
              colorFilter: filter,
            )
          : SvgPicture.asset(
              logo,
              fit: BoxFit.contain,
              alignment: alignment,
              colorFilter: filter,
            ),
    );
  }
}
