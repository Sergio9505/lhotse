import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/brands_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_search_field.dart';
import '../../../core/widgets/lhotse_shell_header.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
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

  List<ProjectData> _searchProjects(List<ProjectData> projects) {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return projects
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q) ||
            p.architect.toLowerCase().contains(q))
        .toList();
  }

  List<BrandData> _searchBrands(List<BrandData> brands) {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return brands
        .where((b) => b.name.toLowerCase().contains(q))
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
    final projects = ref.watch(projectsProvider).valueOrNull ?? const [];
    final brands = ref.watch(brandsProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LhotseShellHeader(
            child: Text(
              'BUSCAR',
              style: AppTypography.headingLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LhotseSearchField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              onClose: hasQuery ? _clearSearch : null,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(projectsProvider);
                ref.invalidate(brandsProvider);
                await Future.wait([
                  ref.read(projectsProvider.future).catchError((_) => <ProjectData>[]),
                  ref.read(brandsProvider.future).catchError((_) => <BrandData>[]),
                ]);
              },
              child: hasQuery
                ? _SearchResults(
                    projectResults: _searchProjects(projects),
                    brandResults: _searchBrands(brands),
                    query: _query,
                    onResultTap: () => _addToRecent(_query),
                  )
                : _IdleContent(
                    recentSearches: _recentSearches,
                    featuredProjects:
                        projects.where((p) => p.isVip).take(3).toList(),
                    onTagTap: _onTagTap,
                    trendingTags: _trendingTags,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Idle state ───────────────────────────────────────────────────────────────

class _IdleContent extends StatelessWidget {
  const _IdleContent({
    required this.recentSearches,
    required this.featuredProjects,
    required this.onTagTap,
    required this.trendingTags,
  });

  final List<String> recentSearches;
  final List<ProjectData> featuredProjects;
  final ValueChanged<String> onTagTap;
  final List<String> trendingTags;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (recentSearches.isNotEmpty) ...[
          _TagSection(
            title: 'RECIENTES',
            tags: recentSearches,
            onTap: onTagTap,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        _TagSection(
          title: 'TENDENCIAS',
          tags: trendingTags,
          onTap: onTagTap,
        ),
        const SizedBox(height: AppSpacing.xl),
        _FeaturedSection(projects: featuredProjects),
      ],
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({
    required this.title,
    required this.tags,
    required this.onTap,
  });

  final String title;
  final List<String> tags;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: tags
                .map((tag) => _TrendingChip(label: tag, onTap: () => onTap(tag)))
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

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({required this.projects});

  final List<ProjectData> projects;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();
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
          for (int i = 0; i < projects.length; i++) ...[
            _FeaturedCard(project: projects[i]),
            if (i < projects.length - 1) const SizedBox(height: AppSpacing.md),
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

// ── Search results ───────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.projectResults,
    required this.brandResults,
    required this.query,
    this.onResultTap,
  });

  final List<ProjectData> projectResults;
  final List<BrandData> brandResults;
  final String query;
  final VoidCallback? onResultTap;

  @override
  Widget build(BuildContext context) {
    if (projectResults.isEmpty && brandResults.isEmpty) {
      return _EmptyResults(query: query);
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
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
          ...brandResults.map((brand) =>
              _BrandResultItem(brand: brand, onTap: onResultTap)),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (projectResults.isNotEmpty) ...[
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
          ...projectResults.map((project) =>
              _ProjectResultItem(project: project, onTap: onResultTap)),
          const SizedBox(height: AppSpacing.xl),
        ],
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

  static const _filter =
      ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn);

  @override
  Widget build(BuildContext context) {
    final logo = brand.logoAsset;
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
            SizedBox(
              width: 48,
              height: 32,
              child: logo != null
                  ? (logo.startsWith('http')
                      ? SvgPicture.network(logo,
                          fit: BoxFit.contain, colorFilter: _filter)
                      : SvgPicture.asset(logo,
                          fit: BoxFit.contain, colorFilter: _filter))
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
            Expanded(
              child: Text(
                brand.tagline ?? brand.name.toUpperCase(),
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.accentMuted),
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
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: LhotseImage(project.imageUrl),
            ),
            const SizedBox(width: AppSpacing.md),
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
