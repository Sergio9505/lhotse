import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_image.dart';
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
  final List<String> _recentSearches = [];

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
    _addToRecent(tag);
  }

  void _addToRecent(String term) {
    if (term.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(term);
      _recentSearches.insert(0, term);
      if (_recentSearches.length > 3) _recentSearches.removeLast();
    });
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
                    onResultTap: () => _addToRecent(_query),
                  )
                : const _IdleContent(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Idle state: Recientes + Tendencias + Destacados
// ---------------------------------------------------------------------------

class _IdleContent extends StatelessWidget {
  const _IdleContent();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SearchScreenState>()!;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (state._recentSearches.isNotEmpty) ...[
          const _RecentSearchesSection(),
          const SizedBox(height: AppSpacing.xl),
        ],
        const _TrendingSection(),
        const SizedBox(height: AppSpacing.xl),
        const _FeaturedSection(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recientes — in-memory recent searches
// ---------------------------------------------------------------------------

class _RecentSearchesSection extends StatelessWidget {
  const _RecentSearchesSection();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SearchScreenState>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECIENTES',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: state._recentSearches
                .map((term) => _TrendingChip(
                      label: term,
                      onTap: () => state._onTagTap(term),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tendencias — trending tags
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
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            width: 0.5,
          ),
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
// Destacados — curated VIP projects
// ---------------------------------------------------------------------------

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection();

  @override
  Widget build(BuildContext context) {
    final featured = mockProjects.where((p) => p.isVip).take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESTACADOS',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < featured.length; i++) ...[
            _FeaturedCard(project: featured[i]),
            if (i < featured.length - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.project});

  final ProjectData project;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/projects/${project.id}'),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: LhotseImage(project.imageUrl),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            project.name.toUpperCase(),
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textPrimary,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Search results — brands + projects
// ---------------------------------------------------------------------------

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.results,
    required this.query,
    this.onResultTap,
  });

  final List<ProjectData> results;
  final String query;
  final VoidCallback? onResultTap;

  @override
  Widget build(BuildContext context) {
    final brandResults = mockBrands
        .where((b) => b.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (results.isEmpty && brandResults.isEmpty) {
      return _EmptyResults(query: query);
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // FIRMAS section
        if (brandResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'FIRMAS',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 1.8,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...brandResults.map((brand) => _BrandResultItem(
                brand: brand,
                onTap: onResultTap,
              )),
          const SizedBox(height: AppSpacing.xl),
        ],

        // PROYECTOS section
        if (results.isNotEmpty) ...[
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
          ...results.map((project) => _ProjectResultItem(
                project: project,
                onTap: onResultTap,
              )),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Documents placeholder
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
            color: Colors.white.withValues(alpha: 0.3),
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

class _BrandResultItem extends StatelessWidget {
  const _BrandResultItem({required this.brand, this.onTap});

  final BrandData brand;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        context.push('/brands/${brand.id}');
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Logo
            SizedBox(
              width: 48,
              height: 32,
              child: brand.logoAsset != null
                  ? SvgPicture.asset(
                      brand.logoAsset!,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textPrimary,
                        BlendMode.srcIn,
                      ),
                    )
                  : Center(
                      child: Text(
                        brand.name.split(' ').map((w) => w[0]).join(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Tagline
            Expanded(
              child: Text(
                brand.tagline ?? brand.name.toUpperCase(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.accentMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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

class _ProjectResultItem extends StatelessWidget {
  const _ProjectResultItem({required this.project, this.onTap});

  final ProjectData project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        context.push('/projects/${project.id}');
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 64,
              height: 64,
              child: LhotseImage(project.imageUrl),
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
