import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_investments.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/domain/user_role.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_filter_tab.dart';
import '../../../core/widgets/lhotse_search_field.dart';
import '../../home/presentation/widgets/project_card.dart';

enum _ActiveTool { none, brands, locations, search }

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  _ActiveTool _activeTool = _ActiveTool.none;
  final Set<String> _selectedBrands = {};
  final Set<String> _selectedLocations = {};
  String _searchQuery = '';
  final _searchController = TextEditingController();

  List<ProjectData> get _availableProjects {
    final investedIds = mockInvestments.map((i) => i.projectId).toSet();
    var projects =
        mockProjects.where((p) => !investedIds.contains(p.id)).toList();

    if (_selectedBrands.isNotEmpty) {
      projects =
          projects.where((p) => _selectedBrands.contains(p.brand)).toList();
    }

    if (_selectedLocations.isNotEmpty) {
      projects = projects
          .where((p) => _selectedLocations.contains(p.location))
          .toList();
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

  List<String> get _uniqueLocations {
    final investedIds = mockInvestments.map((i) => i.projectId).toSet();
    return mockProjects
        .where((p) => !investedIds.contains(p.id))
        .map((p) => p.location)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleTool(_ActiveTool tool) {
    setState(() {
      if (_activeTool == tool) {
        _activeTool = _ActiveTool.none;
      } else {
        _activeTool = tool;
        // Only search is exclusive — clears everything and takes over UI
        if (tool == _ActiveTool.search) {
          _selectedBrands.clear();
          _selectedLocations.clear();
        } else {
          // Switching between brands/locations keeps both selections
          _searchQuery = '';
          _searchController.clear();
        }
      }
    });
  }

  void _toggleBrand(String name) {
    setState(() {
      if (_selectedBrands.contains(name)) {
        _selectedBrands.remove(name);
      } else {
        _selectedBrands.add(name);
      }
    });
  }

  void _toggleLocation(String location) {
    setState(() {
      if (_selectedLocations.contains(location)) {
        _selectedLocations.remove(location);
      } else {
        _selectedLocations.add(location);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final projects = _availableProjects;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const LhotseAppHeader(title: 'OPORTUNIDADES'),

          // Filter bar — text tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: LhotseFilterTab(
                    label: 'FIRMA',
                    isActive: _activeTool == _ActiveTool.brands,
                    hasSelection: _selectedBrands.isNotEmpty,
                    onTap: () => _toggleTool(_ActiveTool.brands),
                  ),
                ),
                Expanded(
                  child: LhotseFilterTab(
                    label: 'UBICACIÓN',
                    isActive: _activeTool == _ActiveTool.locations,
                    hasSelection: _selectedLocations.isNotEmpty,
                    onTap: () => _toggleTool(_ActiveTool.locations),
                  ),
                ),
                Expanded(
                  child: LhotseFilterTab(
                    label: 'BUSCAR',
                    isActive: _activeTool == _ActiveTool.search,
                    onTap: () => _toggleTool(_ActiveTool.search),
                  ),
                ),
              ],
            ),
          ),

          // Tool panels
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
            )
          else if (_activeTool == _ActiveTool.locations)
            _LocationFilterRow(
              locations: _uniqueLocations,
              selectedLocations: _selectedLocations,
              onLocationTap: _toggleLocation,
              onClear: () => setState(() => _selectedLocations.clear()),
            ),

          // Project list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: projects.length,
              itemBuilder: (context, i) {
                return SizedBox(
                  height: 550,
                  child: ProjectCard(
                    project: projects[i],
                    isLocked: projects[i].isVip &&
                        kMockCurrentRole != UserRole.investorVip,
                    onTap: () => context.push('/projects/${projects[i].id}'),
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

// ---------------------------------------------------------------------------
// Brand filter row — reused pattern from AllProjectsScreen
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Location filter row — horizontal scroll of location names
// ---------------------------------------------------------------------------

class _LocationFilterRow extends StatelessWidget {
  const _LocationFilterRow({
    required this.locations,
    required this.selectedLocations,
    required this.onLocationTap,
    required this.onClear,
  });

  final List<String> locations;
  final Set<String> selectedLocations;
  final ValueChanged<String> onLocationTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedLocations.isNotEmpty;
    final itemCount = locations.length + (hasSelection ? 1 : 0);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, i) {
          if (hasSelection && i == locations.length) {
            return GestureDetector(
              onTap: onClear,
              child: Center(
                child: PhosphorIcon(
                  PhosphorIconsThin.x,
                  size: 16,
                  color: AppColors.accentMuted,
                ),
              ),
            );
          }

          final location = locations[i];
          final isSelected = selectedLocations.contains(location);
          final double opacity =
              hasSelection ? (isSelected ? 1.0 : 0.35) : 0.6;

          return GestureDetector(
            onTap: () => onLocationTap(location),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: opacity,
              child: Center(
                child: Text(
                  location.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w500 : FontWeight.w400,
                    letterSpacing: 1.5,
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

