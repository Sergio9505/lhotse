import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/brands_provider.dart';
import '../../../../core/data/projects_provider.dart';
import '../../../../core/data/supabase_provider.dart';
import '../../../../core/domain/project_data.dart';
import '../../../../core/domain/user_role.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_async_list_states.dart';
import '../../../../core/widgets/lhotse_brand_filter_row.dart';
import '../../../home/presentation/widgets/project_showcase_card.dart';

/// Projects catalog body for the Firmas › PROYECTOS sub-tab.
///
/// Filters **only by brand**, and the brand filter is **mandatory**: exactly
/// one firma is always selected (defaults to the first brand — Myttas — and
/// tapping the active one does not clear it). This is the CEO's "filter quickly
/// by firma" requirement. There's no status filter — the selected firm's
/// projects are shown in full, **ordered in-development first, then
/// finalized**; the status is read from each card's byline. No text search
/// here (lives in the global Buscar tab).
class ProjectsArchiveBody extends ConsumerStatefulWidget {
  const ProjectsArchiveBody({super.key});

  @override
  ConsumerState<ProjectsArchiveBody> createState() =>
      _ProjectsArchiveBodyState();
}

class _ProjectsArchiveBodyState extends ConsumerState<ProjectsArchiveBody> {
  String? _selectedBrand;

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final brandsAsync = ref.watch(brandsProvider);
    final projects = projectsAsync.value ?? const [];
    final allBrands = brandsAsync.value ?? const [];
    final projectBrandNames = projects.map((p) => p.brand).toSet();
    final brands = allBrands
        .where((b) => projectBrandNames.contains(b.name))
        .toList();

    // Mandatory single-select: always one brand. Default to the first brand
    // (Myttas today); fall back to it if the stored selection disappeared.
    final selectedBrand =
        (_selectedBrand != null &&
            brands.any((b) => b.name == _selectedBrand))
        ? _selectedBrand
        : brands.firstOrNull?.name;

    // In-development first, then finalized; operator `sort_order` preserved
    // within each group (the source list is already operator-ordered).
    final brandProjects = projects.where((p) => p.brand == selectedBrand);
    final filtered = <ProjectData>[
      ...brandProjects.where((p) => p.phase != ProjectPhase.exited),
      ...brandProjects.where((p) => p.phase == ProjectPhase.exited),
    ];

    return Column(
      children: [
        // Tira 2 (única fila de filtro): row de marcas, obligatorio y visible.
        if (brands.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: LhotseBrandFilterRow(
              brands: brands,
              selectedBrands: {?selectedBrand},
              onBrandTap: (name) => setState(() => _selectedBrand = name),
            ),
          ),
        Expanded(
          child: projectsAsync.hasError
              ? LhotseAsyncError(
                  message: 'No se pudieron cargar los proyectos.',
                  onRetry: () {
                    ref.invalidate(projectsProvider);
                    ref.invalidate(brandsProvider);
                  },
                )
              : projectsAsync.isLoading && projects.isEmpty
              ? const LhotseAsyncLoading()
              : ListView.separated(
                  // top 0: the brand row's bottom gap (AppSpacing.sm) already
                  // sets the controls→content distance (BrandsLayout.contentTop).
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, i) {
                    return ProjectShowcaseCard(
                      project: filtered[i],
                      isLocked:
                          filtered[i].isVip &&
                          ref.read(currentUserRoleProvider) !=
                              UserRole.investorVip,
                      onTap: () => context.push(
                        '/projects/${filtered[i].id}',
                        extra: filtered[i],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
