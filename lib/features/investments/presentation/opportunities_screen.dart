import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_investments.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/domain/user_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_filter_tab.dart';
import '../../home/presentation/widgets/project_card.dart';

enum _ActiveTool { none, locations }

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  BusinessModel? _selectedModel;
  _ActiveTool _activeTool = _ActiveTool.none;
  final Set<String> _selectedLocations = {};

  List<ProjectData> get _availableProjects {
    final investedIds = mockInvestments.map((i) => i.projectId).toSet();
    var projects =
        mockProjects.where((p) => !investedIds.contains(p.id)).toList();

    if (_selectedModel != null) {
      projects = projects.where((p) {
        final brand =
            mockBrands.where((b) => b.name == p.brand).firstOrNull;
        return brand?.businessModel == _selectedModel;
      }).toList();
    }

    if (_selectedLocations.isNotEmpty) {
      projects = projects
          .where((p) => _selectedLocations.contains(p.location))
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

  void _toggleModel(BusinessModel model) {
    setState(() {
      _selectedModel = _selectedModel == model ? null : model;
    });
  }

  void _toggleLocations() {
    setState(() {
      _activeTool = _activeTool == _ActiveTool.locations
          ? _ActiveTool.none
          : _ActiveTool.locations;
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

          // Filter bar
          _FilterBar(
            selectedModel: _selectedModel,
            activeTool: _activeTool,
            hasLocationSelection: _selectedLocations.isNotEmpty,
            onModelTap: _toggleModel,
            onLocationsTap: _toggleLocations,
          ),

          // Location panel
          if (_activeTool == _ActiveTool.locations)
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
// Filter bar — model tabs + location icon
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selectedModel,
    required this.activeTool,
    required this.hasLocationSelection,
    required this.onModelTap,
    required this.onLocationsTap,
  });

  final BusinessModel? selectedModel;
  final _ActiveTool activeTool;
  final bool hasLocationSelection;
  final ValueChanged<BusinessModel> onModelTap;
  final VoidCallback onLocationsTap;

  static const _modelFilters = [
    (model: BusinessModel.compraDirecta, label: 'COMPRA'),
    (model: BusinessModel.coinversion, label: 'COINVERSIÓN'),
    (model: BusinessModel.rentaFija, label: 'RENTA FIJA'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Model tabs
          Row(
            children: List.generate(_modelFilters.length, (i) {
              final filter = _modelFilters[i];
              return Padding(
                padding: EdgeInsets.only(
                    right: i < _modelFilters.length - 1 ? AppSpacing.lg : 0),
                child: LhotseFilterTab(
                  label: filter.label,
                  isActive: selectedModel == filter.model,
                  onTap: () => onModelTap(filter.model),
                ),
              );
            }),
          ),

          const Spacer(),

          // Separator
          Container(width: 1, height: 16, color: AppColors.border),
          const SizedBox(width: AppSpacing.md),

          // Locations tool
          GestureDetector(
            onTap: onLocationsTap,
            child: SizedBox(
              width: 22,
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: PhosphorIcon(
                      PhosphorIconsThin.mapPin,
                      size: 18,
                      color: activeTool == _ActiveTool.locations ||
                              hasLocationSelection
                          ? AppColors.textPrimary
                          : AppColors.accentMuted,
                    ),
                  ),
                  if (hasLocationSelection)
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Location filter row
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
