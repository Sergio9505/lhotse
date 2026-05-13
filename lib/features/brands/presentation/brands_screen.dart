import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/brands_provider.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_wordmark.dart';
import '../../../core/widgets/lhotse_filter_tab.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_shell_header.dart';
import 'widgets/news_archive_body.dart';
import 'widgets/projects_archive_body.dart';

enum _BrandsTab { firmas, proyectos, noticias }

/// Catalog hub for the group — 3 sub-tabs inside a single nav tab:
/// FIRMAS (brand grid, default), PROYECTOS, NOTICIAS. The bottom nav only
/// shows dot indicators so the tab name "Firmas" is not visible globally;
/// the sub-tab row acts as the screen's orientation.
class BrandsScreen extends ConsumerStatefulWidget {
  const BrandsScreen({super.key});

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  _BrandsTab _tab = _BrandsTab.firmas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const LhotseShellHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                // First-level navigation inside the Firmas tab — each sub-tab
                // opens a distinct dataset (brands, projects, news). Peer-
                // equal full-width cells with full-cell underline, matching
                // the fintech premium pattern used in L3 detail tabs.
                Expanded(
                  child: LhotseFilterTab(
                    label: 'Firmas',
                    isActive: _tab == _BrandsTab.firmas,
                    onTap: () => setState(() => _tab = _BrandsTab.firmas),
                    fullWidth: true,
                    editorial: true,
                  ),
                ),
                Expanded(
                  child: LhotseFilterTab(
                    label: 'Proyectos',
                    isActive: _tab == _BrandsTab.proyectos,
                    onTap: () => setState(() => _tab = _BrandsTab.proyectos),
                    fullWidth: true,
                    editorial: true,
                  ),
                ),
                Expanded(
                  child: LhotseFilterTab(
                    label: 'Noticias',
                    isActive: _tab == _BrandsTab.noticias,
                    onTap: () => setState(() => _tab = _BrandsTab.noticias),
                    fullWidth: true,
                    editorial: true,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              _BrandsTab.firmas => const _BrandsGrid(),
              _BrandsTab.proyectos => const ProjectsArchiveBody(),
              _BrandsTab.noticias => const NewsArchiveBody(),
            },
          ),
        ],
      ),
    );
  }
}

class _BrandsGrid extends ConsumerWidget {
  const _BrandsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);
    return brandsAsync.when(
      data: (brands) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.lg,
          childAspectRatio: 0.82,
        ),
        itemCount: brands.length,
        itemBuilder: (context, i) => _BrandCard(brand: brands[i]),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 1.5),
      ),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.brand});

  final BrandData brand;

  @override
  Widget build(BuildContext context) {
    final hasCover = brand.coverImageUrl.isNotEmpty;
    final logo = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: BrandWordmark(brand: brand, size: BrandWordmarkSize.sm),
    );
    return GestureDetector(
      onTap: () => context.push('/brands/${brand.id}', extra: brand),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.18),
            width: 0.5,
          ),
        ),
        child: hasCover
            ? Column(
                children: [
                  Expanded(flex: 25, child: Center(child: logo)),
                  Expanded(
                    flex: 75,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: SizedBox.expand(
                        child: LhotseImage(brand.coverImageUrl),
                      ),
                    ),
                  ),
                ],
              )
            : Center(child: logo),
      ),
    );
  }
}
