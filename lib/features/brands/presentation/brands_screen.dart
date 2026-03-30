import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/theme/app_theme.dart';

class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg + 2, topPadding + 16, AppSpacing.lg, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FIRMAS',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SvgPicture.asset(
                  'assets/images/lhotse_logo.svg',
                  width: 20,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),

          // Brand list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 32),
              itemCount: mockBrands.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) =>
                  _BrandCard(brand: mockBrands[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.brand});

  final BrandData brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 192,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 25,
            offset: Offset(0, 20),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
        borderRadius: BorderRadius.circular(0),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover image
          Image.network(
            brand.coverImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppColors.surface),
          ),

          // Gradient overlay (bottom dark → top transparent)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 0.5, 1.0],
                colors: [
                  Color(0xCC000000), // black 80%
                  Color(0x33000000), // black 20%
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Dark tint overlay
          const ColoredBox(color: Color(0x1A000000)),

          // Logo (centered)
          if (brand.logoAsset != null)
            Center(
              child: SvgPicture.asset(
                brand.logoAsset!,
                height: 48,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            )
          else
            Center(
              child: Text(
                brand.name[0],
                style: AppTypography.displayLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

          // Brand name (bottom-left)
          Positioned(
            left: 16,
            bottom: 16,
            child: Text(
              brand.name.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
