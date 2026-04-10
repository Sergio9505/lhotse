import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_shell_header.dart';

class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          LhotseShellHeader(
            child: Text(
              'FIRMAS',
              style: AppTypography.headingLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Brand grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.0,
              ),
              itemCount: mockBrands.length,
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

          // Logo + name (centered)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (brand.logoAsset != null)
                  SvgPicture.asset(
                    brand.logoAsset!,
                    height: 36,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  )
                else
                  Text(
                    brand.name[0],
                    style: AppTypography.displayLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  brand.name.toUpperCase(),
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
