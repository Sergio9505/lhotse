import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/brands_provider.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_shell_header.dart';

class BrandsScreen extends ConsumerWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          LhotseShellHeader(
            child: Text(
              'FIRMAS',
              style: AppTypography.headingLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: brandsAsync.when(
              data: (brands) => GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.0,
                ),
                itemCount: brands.length,
                itemBuilder: (context, i) => _BrandCard(brand: brands[i]),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
              error: (e, _) => Center(child: Text('$e')),
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

  static const _filter = ColorFilter.mode(
    AppColors.textPrimary,
    BlendMode.srcIn,
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/brands/${brand.id}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Center(
          child: brand.logoAsset != null
              ? SizedBox(
                  width: 100,
                  height: 40,
                  child: brand.logoAsset!.startsWith('http')
                      ? SvgPicture.network(
                          brand.logoAsset!,
                          fit: BoxFit.contain,
                          colorFilter: _filter,
                        )
                      : SvgPicture.asset(
                          brand.logoAsset!,
                          fit: BoxFit.contain,
                          colorFilter: _filter,
                        ),
                )
              : Text(
                  brand.name.toUpperCase(),
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}
