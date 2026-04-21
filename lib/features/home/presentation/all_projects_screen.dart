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
import 'widgets/project_card.dart';

class AllProjectsScreen extends ConsumerStatefulWidget {
  const AllProjectsScreen({super.key});

  @override
  ConsumerState<AllProjectsScreen> createState() => _AllProjectsScreenState();
}

enum _ActiveTool { none, brands, search }

/// Single-select status filter. Null = default catalog view (construction +
/// exited). Projects still in `pre_construction` (open fundraising, work not
/// started) are not shown here — they live in Strategy → Oportunidades so the
/// two screens have distinct intents: this one is the portfolio catalog,
/// Strategy surfaces deals the user can join.
enum _StatusFilter {
  construction, // phase = construction
  exited, // phase = exited
}

class _AllProjectsScreenState extends ConsumerState<AllProjectsScreen> {
  _StatusFilter? _selectedStatus;
  _ActiveTool _activeTool = _ActiveTool.none;
  final Set<String> _selectedBrands = {};
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProjectData> _applyFilters(List<ProjectData> projects) {
    // Hide pre_construction projects; they surface only in Strategy →
    // Oportunidades. This screen is the portfolio catalog.
    var result = projects
        .where((p) => p.phase != ProjectPhase.preConstruction)
        .toList();
    if (_selectedStatus != null) {
      result = result.where((p) => switch (_selectedStatus!) {
            _StatusFilter.construction => p.phase == ProjectPhase.construction,
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

          Expanded(
            child: ref.watch(projectsProvider).isLoading && projects.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 1.5))
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      return SizedBox(
                        height: 550,
                        child: ProjectCard(
                          project: filtered[i],
                          isLocked: filtered[i].isVip &&
                              ref.read(currentUserRoleProvider) !=
                                  UserRole.investorVip,
                          onTap: () =>
                              context.push('/projects/${filtered[i].id}'),
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
    (status: _StatusFilter.construction, label: 'EN DESARROLLO'),
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
