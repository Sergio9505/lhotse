import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_search_field.dart';
import '../../../core/widgets/lhotse_shell_header.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _trendingTags = [
    'Madrid Centro',
    'Dubai',
    'Vellte',
    'Residencial',
    'Marbella',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProjectData> get _searchResults {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return mockProjects
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q) ||
            p.architect.toLowerCase().contains(q))
        .toList();
  }

  void _onTagTap(String tag) {
    _searchController.text = tag;
    setState(() => _query = tag);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          LhotseShellHeader(
            child: Text(
              'BUSCAR',
              style: AppTypography.headingLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LhotseSearchField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              onClose: hasQuery ? _clearSearch : null,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Content
          Expanded(
            child: hasQuery
                ? _SearchResults(
                    results: _searchResults,
                    query: _query,
                  )
                : const _IdleContent(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Idle state: Tendencias + Colecciones
// ---------------------------------------------------------------------------

class _IdleContent extends StatelessWidget {
  const _IdleContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        _TrendingSection(),
        SizedBox(height: AppSpacing.xl),
        _CollectionsSection(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tendencias — horizontal chip row
// ---------------------------------------------------------------------------

class _TrendingSection extends StatelessWidget {
  const _TrendingSection();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SearchScreenState>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TENDENCIAS',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _SearchScreenState._trendingTags
                .map((tag) => _TrendingChip(
                      label: tag,
                      onTap: () => state._onTagTap(tag),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TrendingChip extends StatelessWidget {
  const _TrendingChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Colecciones — 2-column brand grid
// ---------------------------------------------------------------------------

class _CollectionsSection extends StatelessWidget {
  const _CollectionsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COLECCIONES',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 192 / 240,
            ),
            itemCount: mockBrands.length,
            itemBuilder: (context, i) {
              final brand = mockBrands[i];
              return _CollectionCard(
                name: brand.name,
                imageUrl: brand.coverImageUrl,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.name,
    required this.imageUrl,
  });

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppColors.surface),
          ),

          // Gradient overlay
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 0.5, 1.0],
                colors: [
                  Color(0x99000000),
                  Color(0x00000000),
                  Color(0x00000000),
                ],
              ),
            ),
          ),

          // Brand name
          Positioned(
            left: 13,
            bottom: 12,
            child: Text(
              name.toUpperCase(),
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search results
// ---------------------------------------------------------------------------

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.results,
    required this.query,
  });

  final List<ProjectData> results;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return _EmptyResults(query: query);
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Projects header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'PROYECTOS',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 1.8,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Project results
        ...results.map((project) => _ProjectResultItem(project: project)),

        const SizedBox(height: AppSpacing.xl),

        // Documents section placeholder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'DOCUMENTOS',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 1.8,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIconsThin.fileText,
                  size: 20,
                  color: AppColors.accentMuted,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Los documentos de inversión estarán disponibles próximamente',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.accentMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _ProjectResultItem extends StatelessWidget {
  const _ProjectResultItem({required this.project});

  final ProjectData project;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/projects/${project.id}'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Image.network(
                  project.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: AppColors.surface),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name.toUpperCase(),
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        project.brand.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '·',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          project.location.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accentMuted,
                            letterSpacing: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            const PhosphorIcon(
              PhosphorIconsThin.arrowUpRight,
              size: 18,
              color: AppColors.accentMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sin resultados para "$query"',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Prueba con otro término de búsqueda',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.accentMuted,
            ),
          ),
        ],
      ),
    );
  }
}
