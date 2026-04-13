import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_investments.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
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
                  child: _FilterTab(
                    label: 'FIRMA',
                    isActive: _activeTool == _ActiveTool.brands,
                    hasSelection: _selectedBrands.isNotEmpty,
                    onTap: () => _toggleTool(_ActiveTool.brands),
                  ),
                ),
                Expanded(
                  child: _FilterTab(
                    label: 'UBICACIÓN',
                    isActive: _activeTool == _ActiveTool.locations,
                    hasSelection: _selectedLocations.isNotEmpty,
                    onTap: () => _toggleTool(_ActiveTool.locations),
                  ),
                ),
                Expanded(
                  child: _FilterTab(
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
            _BrandFilterRow(
              selectedBrands: _selectedBrands,
              onBrandTap: _toggleBrand,
              onClear: () => setState(() => _selectedBrands.clear()),
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
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, i) {
          if (hasSelection && i == mockBrands.length) {
            return GestureDetector(
              onTap: onClear,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 32,
                    child: PhosphorIcon(
                      PhosphorIconsThin.x,
                      size: 16,
                      color: AppColors.accentMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'LIMPIAR',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.accentMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (brand.logoAsset != null)
                    SizedBox(
                      width: 64,
                      height: 32,
                      child: SvgPicture.asset(
                        brand.logoAsset!,
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          AppColors.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    )
                  else
                    Text(
                      brand.name[0],
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    brand.name.toUpperCase(),
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
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
                        isSelected ? FontWeight.w700 : FontWeight.w400,
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

// ---------------------------------------------------------------------------
// Filter tab — text button with animated underline
// ---------------------------------------------------------------------------

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.hasSelection = false,
  });

  final String label;
  final bool isActive;
  final bool hasSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlighted = isActive || hasSelection;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: highlighted
                      ? AppColors.textPrimary
                      : AppColors.accentMuted,
                  fontWeight: highlighted ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: 1.5,
                ),
              ),
              if (hasSelection) ...[
                const SizedBox(width: 5),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: 1.5,
            width: isActive ? 24.0 : 0.0,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
