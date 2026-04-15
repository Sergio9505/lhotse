import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/projects_provider.dart';
import '../../../core/data/supabase_provider.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/domain/user_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_filter_tab.dart';
import '../../home/presentation/widgets/project_card.dart';

enum _ActiveTool { none, locations }

class OpportunitiesScreen extends ConsumerStatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  ConsumerState<OpportunitiesScreen> createState() =>
      _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends ConsumerState<OpportunitiesScreen> {
  BusinessModel? _selectedModel;
  _ActiveTool _activeTool = _ActiveTool.none;
  final Set<String> _selectedLocations = {};

  String? get _modelParam => switch (_selectedModel) {
        BusinessModel.directPurchase => 'direct_purchase',
        BusinessModel.coinvestment => 'coinvestment',
        BusinessModel.fixedIncome => 'fixed_income',
        null => null,
      };

  Map<String, String?> get _opportunityParams => {
        'model': _modelParam,
        'location': _selectedLocations.length == 1
            ? _selectedLocations.first
            : null,
      };

  List<ProjectData> _applyLocalFilters(List<ProjectData> projects) {
    if (_selectedLocations.isEmpty) return projects;
    return projects
        .where((p) => _selectedLocations.contains(p.location))
        .toList();
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
    final allProjects =
        ref.watch(opportunitiesProvider(_opportunityParams)).valueOrNull ??
            const [];
    final projects = _applyLocalFilters(allProjects);

    final uniqueLocations =
        allProjects.map((p) => p.location).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const LhotseAppHeader(title: 'OPORTUNIDADES'),

          _FilterBar(
            selectedModel: _selectedModel,
            activeTool: _activeTool,
            hasLocationSelection: _selectedLocations.isNotEmpty,
            onModelTap: _toggleModel,
            onLocationsTap: _toggleLocations,
          ),

          if (_activeTool == _ActiveTool.locations)
            _LocationFilterRow(
              locations: uniqueLocations,
              selectedLocations: _selectedLocations,
              onLocationTap: _toggleLocation,
              onClear: () => setState(() => _selectedLocations.clear()),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(opportunitiesProvider);
                await ref
                    .read(opportunitiesProvider(_opportunityParams).future)
                    .catchError((_) => <ProjectData>[]);
              },
              child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: projects.length,
              itemBuilder: (context, i) {
                return SizedBox(
                  height: 550,
                  child: ProjectCard(
                    project: projects[i],
                    isLocked: projects[i].isVip &&
                        ref.read(currentUserRoleProvider) !=
                            UserRole.investorVip,
                    onTap: () => context.push('/projects/${projects[i].id}'),
                  ),
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

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
    (model: BusinessModel.directPurchase, label: 'COMPRA'),
    (model: BusinessModel.coinvestment, label: 'COINVERSIÓN'),
    (model: BusinessModel.fixedIncome, label: 'RENTA FIJA'),
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
          Container(width: 1, height: 16, color: AppColors.border),
          const SizedBox(width: AppSpacing.md),
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

// ── Location filter row ───────────────────────────────────────────────────────

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
