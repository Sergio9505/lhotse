import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/domain/user_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_filter_tab.dart';
import '../../../core/widgets/lhotse_search_field.dart';
import 'widgets/project_card.dart';

class AllProjectsScreen extends StatefulWidget {
  const AllProjectsScreen({super.key});

  @override
  State<AllProjectsScreen> createState() => _AllProjectsScreenState();
}

enum _ActiveTool { none, brands, search }

class _AllProjectsScreenState extends State<AllProjectsScreen> {
  ProjectStatus? _selectedStatus;
  _ActiveTool _activeTool = _ActiveTool.none;
  final Set<String> _selectedBrands = {};
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProjectData> get _filteredProjects {
    var projects = mockProjects;

    if (_selectedStatus != null) {
      projects = projects.where((p) => p.status == _selectedStatus).toList();
    }

    if (_selectedBrands.isNotEmpty) {
      projects =
          projects.where((p) => _selectedBrands.contains(p.brand)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      projects = projects
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q))
          .toList();
    }

    return projects;
  }

  void _toggleStatus(ProjectStatus status) {
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
        // Clear the other tool's state
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          LhotseAppHeader(title: 'PROYECTOS', onBack: () => context.pop()),

          // Filter bar — always visible
          _FilterBar(
            selectedStatus: _selectedStatus,
            activeTool: _activeTool,
            hasBrandSelection: _selectedBrands.isNotEmpty,
            onStatusTap: _toggleStatus,
            onBrandsTap: () => _toggleTool(_ActiveTool.brands),
            onSearchTap: () => _toggleTool(_ActiveTool.search),
          ),

          // Tool panel
          if (_activeTool == _ActiveTool.search)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: LhotseSearchField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v),
                onClose: () => _toggleTool(_ActiveTool.search),
              ),
            )
          else if (_activeTool == _ActiveTool.brands)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _BrandFilterRow(
                selectedBrands: _selectedBrands,
                onBrandTap: _toggleBrand,
                onClear: () => setState(() => _selectedBrands.clear()),
              ),
            ),

          // Project list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _filteredProjects.length,
              itemBuilder: (context, i) {
                return SizedBox(
                  height: 550,
                  child: ProjectCard(
                    project: _filteredProjects[i],
                    isLocked: _filteredProjects[i].isVip &&
                        kMockCurrentRole != UserRole.investorVip,
                    onTap: () =>
                        context.push('/projects/${_filteredProjects[i].id}'),
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

  final ProjectStatus? selectedStatus;
  final _ActiveTool activeTool;
  final bool hasBrandSelection;
  final ValueChanged<ProjectStatus> onStatusTap;
  final VoidCallback onBrandsTap;
  final VoidCallback onSearchTap;

  static const _statusFilters = [
    (status: ProjectStatus.enDesarrollo, label: 'EN DESARROLLO'),
    (status: ProjectStatus.cerrado, label: 'CERRADOS'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status filters
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

          // Separator
          Container(width: 1, height: 16, color: AppColors.border),
          const SizedBox(width: AppSpacing.md),

          // Brands tool
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
                      color: activeTool == _ActiveTool.brands ||
                              hasBrandSelection
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

          // Search tool
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

class _BrandFilterRow extends StatelessWidget {
  const _BrandFilterRow({
    required this.selectedBrands,
    required this.onBrandTap,
    required this.onClear,
  });

  final Set<String> selectedBrands;
  final ValueChanged<String> onBrandTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedBrands.isNotEmpty;
    final itemCount = mockBrands.length + (hasSelection ? 1 : 0);

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, i) {
          // Clear button at the end
          if (hasSelection && i == mockBrands.length) {
            return GestureDetector(
              onTap: onClear,
              child: const SizedBox(
                height: 32,
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIconsThin.x,
                    size: 16,
                    color: AppColors.accentMuted,
                  ),
                ),
              ),
            );
          }

          final brand = mockBrands[i];
          final isSelected = selectedBrands.contains(brand.name);
          final double opacity =
              hasSelection ? (isSelected ? 1.0 : 0.35) : 0.6;

          return GestureDetector(
            onTap: () => onBrandTap(brand.name),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: opacity,
              child: Center(
                child: SizedBox(
                  width: 80,
                  height: 44,
                  child: Center(
                    child: brand.logoAsset != null
                        ? SizedBox(
                            width: 56,
                            height: 24,
                            child: SvgPicture.asset(
                              brand.logoAsset!,
                              fit: BoxFit.contain,
                              colorFilter: const ColorFilter.mode(
                                AppColors.textPrimary,
                                BlendMode.srcIn,
                              ),
                            ),
                          )
                        : Text(
                            brand.name[0],
                            style: AppTypography.headingMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
