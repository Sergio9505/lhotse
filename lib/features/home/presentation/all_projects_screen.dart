import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/brands_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../../core/data/supabase_provider.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/domain/user_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_brand_filter_row.dart';
import '../../../core/widgets/lhotse_filter_tab.dart';
import '../../../core/widgets/lhotse_search_field.dart';
import '../../../core/widgets/scroll_aware_filter_bar.dart';
import 'widgets/project_showcase_card.dart';

class AllProjectsScreen extends ConsumerStatefulWidget {
  const AllProjectsScreen({super.key});

  @override
  ConsumerState<AllProjectsScreen> createState() => _AllProjectsScreenState();
}

enum _ActiveTool { none, brands, search }

/// Single-select status filter for the projects catalog. `inDevelopment`
/// matches both `preConstruction` (any fundraising state) and `construction`,
/// collapsing the two phases into a single user-facing state. `null` shows
/// everything (TODOS).
enum _StatusFilter {
  inDevelopment, // phase = preConstruction OR construction
  exited, // phase = exited
}

class _AllProjectsScreenState extends ConsumerState<AllProjectsScreen> {
  _StatusFilter? _selectedStatus;
  _ActiveTool _activeTool = _ActiveTool.none;
  final Set<String> _selectedBrands = {};
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<ProjectData> _applyFilters(List<ProjectData> projects) {
    var result = projects.toList();
    if (_selectedStatus != null) {
      result = result.where((p) => switch (_selectedStatus!) {
            _StatusFilter.inDevelopment =>
              p.phase == ProjectPhase.preConstruction ||
                  p.phase == ProjectPhase.construction,
            _StatusFilter.exited => p.phase == ProjectPhase.exited,
          }).toList();
    }
    if (_selectedBrands.isNotEmpty) {
      result = result.where((p) => _selectedBrands.contains(p.brand)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  void _toggleStatus(_StatusFilter status) {
    setState(() {
      _selectedStatus = _selectedStatus == status ? null : status;
    });
  }

  void _toggleTool(_ActiveTool tool) {
    setState(() {
      if (_activeTool == tool) {
        _activeTool = _ActiveTool.none;
      } else {
        _activeTool = tool;
        if (tool == _ActiveTool.brands) {
          _searchQuery = '';
          _searchController.clear();
        } else {
          _selectedBrands.clear();
        }
      }
    });
  }

  void _toggleBrand(String brandName) {
    setState(() {
      if (_selectedBrands.contains(brandName)) {
        _selectedBrands.remove(brandName);
      } else {
        _selectedBrands.add(brandName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider).valueOrNull ?? const [];
    final allBrands = ref.watch(brandsProvider).valueOrNull ?? const [];
    final projectBrandNames = projects.map((p) => p.brand).toSet();
    final brands = allBrands.where((b) => projectBrandNames.contains(b.name)).toList();
    final filtered = _applyFilters(projects);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          LhotseAppHeader(title: 'PROYECTOS', onBack: () => context.pop()),

          ScrollAwareFilterBar(
            scrollController: _scrollController,
            expanded: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilterBar(
                  selectedStatus: _selectedStatus,
                  activeTool: _activeTool,
                  hasBrandSelection: _selectedBrands.isNotEmpty,
                  onStatusTap: _toggleStatus,
                  onBrandsTap: () => _toggleTool(_ActiveTool.brands),
                  onSearchTap: () => _toggleTool(_ActiveTool.search),
                ),
                if (_activeTool == _ActiveTool.search)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                    child: LhotseSearchField(
                      controller: _searchController,
                      hint: 'Buscar proyectos, marcas, ubicaciones...',
                      autofocus: true,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      onClose: () => _toggleTool(_ActiveTool.search),
                    ),
                  )
                else if (_activeTool == _ActiveTool.brands)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: LhotseBrandFilterRow(
                      brands: brands,
                      selectedBrands: _selectedBrands,
                      onBrandTap: _toggleBrand,
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: ref.watch(projectsProvider).isLoading && projects.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 1.5))
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) {
                      return ProjectShowcaseCard(
                        project: filtered[i],
                        isLeadStory: i == 0,
                        isLocked: filtered[i].isVip &&
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
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selectedStatus,
    required this.activeTool,
    required this.hasBrandSelection,
    required this.onStatusTap,
    required this.onBrandsTap,
    required this.onSearchTap,
  });

  final _StatusFilter? selectedStatus;
  final _ActiveTool activeTool;
  final bool hasBrandSelection;
  final ValueChanged<_StatusFilter> onStatusTap;
  final VoidCallback onBrandsTap;
  final VoidCallback onSearchTap;

  static const _statusFilters = [
    (status: _StatusFilter.inDevelopment, label: 'EN DESARROLLO'),
    (status: _StatusFilter.exited, label: 'FINALIZADOS'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: List.generate(_statusFilters.length, (i) {
              final filter = _statusFilters[i];
              return Padding(
                padding: EdgeInsets.only(
                    right: i < _statusFilters.length - 1 ? AppSpacing.lg : 0),
                child: LhotseFilterTab(
                  label: filter.label,
                  isActive: selectedStatus == filter.status,
                  onTap: () => onStatusTap(filter.status),
                ),
              );
            }),
          ),
          const Spacer(),
          Container(width: 1, height: 16, color: AppColors.border),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: onBrandsTap,
            child: SizedBox(
              width: 22,
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: PhosphorIcon(
                      PhosphorIconsThin.stack,
                      size: 18,
                      color: activeTool == _ActiveTool.brands || hasBrandSelection
                          ? AppColors.textPrimary
                          : AppColors.accentMuted,
                    ),
                  ),
                  if (hasBrandSelection)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: onSearchTap,
            child: PhosphorIcon(
              PhosphorIconsThin.magnifyingGlass,
              size: 18,
              color: activeTool == _ActiveTool.search
                  ? AppColors.textPrimary
                  : AppColors.accentMuted,
            ),
          ),
        ],
      ),
    );
  }
}
