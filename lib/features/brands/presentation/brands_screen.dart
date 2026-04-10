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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (brand.logoAsset != null)
            SvgPicture.asset(
              brand.logoAsset!,
              height: 40,
              colorFilter: const ColorFilter.mode(
                AppColors.textPrimary,
                BlendMode.srcIn,
              ),
            )
          else
            Text(
              brand.name[0],
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            brand.name.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.accentMuted,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}
