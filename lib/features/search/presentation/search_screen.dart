import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/assets_provider.dart';
import '../../../core/data/brands_provider.dart';
import '../../../core/data/document_categories_provider.dart';
import '../../../core/data/documents_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../../core/domain/asset_data.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/domain/document_data.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/search_utils.dart';
import '../../../core/widgets/lhotse_doc_row.dart';
import '../../../core/widgets/lhotse_documents_section.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_search_field.dart';
import '../../../core/widgets/lhotse_shell_header.dart';
import '../../investments/data/investments_provider.dart';
import '../../investments/domain/coinvestment_contract_data.dart';
import '../../investments/domain/fixed_income_contract_data.dart';
import '../../investments/domain/purchase_contract_data.dart';

/// Search tab — pure text search across brands, projects, assets and the
/// user's documents. Idle state shows trending tags, recent searches, and
/// featured VIP projects. Catalog/news browsing lives in the Firmas tab.
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
    final q = normalizeForSearch(_query);
    return projects.where((p) {
      final haystack = [p.name, p.brand, p.location, p.architect]
          .map(normalizeForSearch)
          .join(' ');
      return haystack.contains(q);
    }).toList();
  }

  List<BrandData> _searchBrands(List<BrandData> brands) {
    if (_query.isEmpty) return [];
    final q = normalizeForSearch(_query);
    return brands.where((b) {
      final haystack = [b.name, b.tagline, b.description]
          .map(normalizeForSearch)
          .join(' ');
      return haystack.contains(q);
    }).toList();
  }

  List<AssetData> _searchAssets(List<AssetData> assets) {
    if (_query.isEmpty) return [];
    final q = normalizeForSearch(_query);
    return assets.where((a) {
      final haystack = [a.address, a.city, a.country, a.cadastralReference]
          .map(normalizeForSearch)
          .join(' ');
      return haystack.contains(q);
    }).toList();
  }

  List<DocumentData> _searchDocsDirect(List<DocumentData> docs) {
    if (_query.isEmpty) return [];
    final q = normalizeForSearch(_query);
    return docs
        .where((d) => normalizeForSearch(d.name).contains(q))
        .toList();
  }

  List<DocumentData> _contextualDocs({
    required List<DocumentData> allDocs,
    required Set<String> matchedBrandIds,
    required Set<String> matchedProjectIds,
    required Set<String> matchedAssetIds,
    required List<PurchaseContractData> purchaseContracts,
    required List<CoinvestmentContractData> coinvestmentContracts,
    required List<FixedIncomeContractData> fixedIncomeContracts,
  }) {
    if (matchedBrandIds.isEmpty &&
        matchedProjectIds.isEmpty &&
        matchedAssetIds.isEmpty) {
      return const [];
    }
    final purchaseIds = purchaseContracts
        .where((c) =>
            matchedBrandIds.contains(c.brandId) ||
            matchedAssetIds.contains(c.assetId))
        .map((c) => c.id)
        .toSet();
    final coinvestIds = coinvestmentContracts
        .where((c) =>
            matchedBrandIds.contains(c.brandId) ||
            matchedProjectIds.contains(c.projectId))
        .map((c) => c.id)
        .toSet();
    final fiIds = fixedIncomeContracts
        .where((c) => matchedBrandIds.contains(c.brandId))
        .map((c) => c.id)
        .toSet();
    return allDocs.where((d) {
      if (d.scope == 'project' && d.projectId != null) {
        return matchedProjectIds.contains(d.projectId);
      }
      if (d.scope == 'asset' && d.assetId != null) {
        return matchedAssetIds.contains(d.assetId);
      }
      if (d.scope == 'investor') {
        if (d.relatedPurchaseId != null && purchaseIds.contains(d.relatedPurchaseId)) return true;
        if (d.relatedCoinvestmentId != null && coinvestIds.contains(d.relatedCoinvestmentId)) return true;
        if (d.relatedFixedIncomeId != null && fiIds.contains(d.relatedFixedIncomeId)) return true;
      }
      return false;
    }).toList();
  }

  String? _docSubtitle(
    DocumentData doc, {
    required List<BrandData> brands,
    required List<ProjectData> projects,
    required List<AssetData> assets,
    required List<PurchaseContractData> purchaseContracts,
    required List<CoinvestmentContractData> coinvestmentContracts,
    required List<FixedIncomeContractData> fixedIncomeContracts,
  }) {
    if (doc.scope == 'project' && doc.projectId != null) {
      return projects
          .where((p) => p.id == doc.projectId)
          .firstOrNull
          ?.name
          .toUpperCase();
    }
    if (doc.scope == 'asset' && doc.assetId != null) {
      return assets
          .where((a) => a.id == doc.assetId)
          .firstOrNull
          ?.address
          ?.toUpperCase();
    }
    if (doc.scope == 'investor') {
      if (doc.relatedPurchaseId != null) {
        final c = purchaseContracts
            .where((c) => c.id == doc.relatedPurchaseId)
            .firstOrNull;
        final addr = c?.assetName;
        if (addr != null && addr.isNotEmpty) return addr.toUpperCase();
        if (c?.assetId != null) {
          return assets
              .where((a) => a.id == c!.assetId)
              .firstOrNull
              ?.address
              ?.toUpperCase();
        }
        return null;
      }
      if (doc.relatedCoinvestmentId != null) {
        return coinvestmentContracts
            .where((c) => c.id == doc.relatedCoinvestmentId)
            .firstOrNull
            ?.projectName
            .toUpperCase();
      }
      if (doc.relatedFixedIncomeId != null) {
        return fixedIncomeContracts
            .where((c) => c.id == doc.relatedFixedIncomeId)
            .firstOrNull
            ?.offeringName
            .toUpperCase();
      }
    }
    return null;
  }

  void _openDoc(
    BuildContext context,
    DocumentData doc, {
    required List<PurchaseContractData> purchaseContracts,
    required List<CoinvestmentContractData> coinvestmentContracts,
    required List<FixedIncomeContractData> fixedIncomeContracts,
  }) {
    if (doc.scope == 'project' && doc.projectId != null) {
      context.push('/projects/${doc.projectId}');
      return;
    }
    // scope='asset' has no standalone route yet (see ROADMAP)
    if (doc.scope == 'investor') {
      if (doc.relatedPurchaseId != null) {
        final contract = purchaseContracts
            .where((c) => c.id == doc.relatedPurchaseId)
            .firstOrNull;
        if (contract == null) return;
        context.push(
          '/investments/detail/purchase/${contract.id}',
          extra: (brandName: '', contract: contract),
        );
        return;
      }
      if (doc.relatedCoinvestmentId != null) {
        final contract = coinvestmentContracts
            .where((c) => c.id == doc.relatedCoinvestmentId)
            .firstOrNull;
        if (contract == null) return;
        context.push(
          '/investments/detail/coinvestment/${contract.id}',
          extra: (contract: contract, brandName: ''),
        );
        return;
      }
      if (doc.relatedFixedIncomeId != null) {
        final contract = fixedIncomeContracts
            .where((c) => c.id == doc.relatedFixedIncomeId)
            .firstOrNull;
        if (contract == null) return;
        context.push('/investments/brand/${contract.brandId}');
        return;
      }
    }
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
    final assets = ref.watch(assetsProvider).valueOrNull ?? const [];
    final allDocs =
        ref.watch(allUserDocumentsProvider).valueOrNull ?? const [];
    final categories =
        ref.watch(allDocumentCategoriesProvider).valueOrNull ?? const [];
    final purchaseContracts =
        ref.watch(purchaseContractsProvider).valueOrNull ?? const [];
    final coinvestmentContracts =
        ref.watch(coinvestmentContractsProvider).valueOrNull ?? const [];
    final fixedIncomeContracts =
        ref.watch(fixedIncomeContractsProvider).valueOrNull ?? const [];

    List<DocumentData> docResults = const [];
    List<AssetData> assetResults = const [];
    List<BrandData> brandResults = const [];
    List<ProjectData> projectResults = const [];

    if (hasQuery) {
      brandResults = _searchBrands(brands);
      projectResults = _searchProjects(projects);
      assetResults = _searchAssets(assets);
      final directDocs = _searchDocsDirect(allDocs);
      final contextualDocs = _contextualDocs(
        allDocs: allDocs,
        matchedBrandIds: brandResults.map((b) => b.id).toSet(),
        matchedProjectIds: projectResults.map((p) => p.id).toSet(),
        matchedAssetIds: assetResults.map((a) => a.id).toSet(),
        purchaseContracts: purchaseContracts,
        coinvestmentContracts: coinvestmentContracts,
        fixedIncomeContracts: fixedIncomeContracts,
      );
      final seen = <String>{};
      docResults = [
        for (final d in [...directDocs, ...contextualDocs])
          if (seen.add(d.id)) d,
      ];
    }

    final docSubtitles = <String, String>{
      for (final d in docResults)
        if (_docSubtitle(
              d,
              brands: brands,
              projects: projects,
              assets: assets,
              purchaseContracts: purchaseContracts,
              coinvestmentContracts: coinvestmentContracts,
              fixedIncomeContracts: fixedIncomeContracts,
            ) !=
            null)
          d.id: _docSubtitle(
            d,
            brands: brands,
            projects: projects,
            assets: assets,
            purchaseContracts: purchaseContracts,
            coinvestmentContracts: coinvestmentContracts,
            fixedIncomeContracts: fixedIncomeContracts,
          )!,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LhotseShellHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LhotseSearchField(
              controller: _searchController,
              hint: 'Buscar proyectos, marcas, ubicaciones...',
              onChanged: (v) => setState(() => _query = v),
              onClose: hasQuery ? _clearSearch : null,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: hasQuery
                ? _SearchResults(
                    projectResults: projectResults,
                    brandResults: brandResults,
                    assetResults: assetResults,
                    docResults: docResults,
                    docSubtitles: docSubtitles,
                    categories: categories,
                    query: _query,
                    onResultTap: () => _addToRecent(_query),
                    onDocTap: (doc) {
                      _addToRecent(_query);
                      _openDoc(
                        context,
                        doc,
                        purchaseContracts: purchaseContracts,
                        coinvestmentContracts: coinvestmentContracts,
                        fixedIncomeContracts: fixedIncomeContracts,
                      );
                    },
                  )
                : _IdleContent(
                    recentSearches: _recentSearches,
                    featuredProjects:
                        projects.where((p) => p.isVip).take(3).toList(),
                    onTagTap: _onTagTap,
                    trendingTags: _trendingTags,
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
            style: AppTypography.labelUppercaseMd.copyWith(
              color: AppColors.textPrimary,
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
          style: AppTypography.annotation.copyWith(
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
            style: AppTypography.labelUppercaseMd.copyWith(
              color: AppColors.textPrimary,
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
      onTap: () => context.push('/projects/${project.id}', extra: project),
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
            style: AppTypography.titleUppercase.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                project.brand.toUpperCase(),
                style: AppTypography.labelUppercaseSm.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '·',
                  style: AppTypography.labelUppercaseSm.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  project.location.toUpperCase(),
                  style: AppTypography.labelUppercaseSm.copyWith(
                    color: AppColors.accentMuted,
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
    required this.assetResults,
    required this.docResults,
    required this.docSubtitles,
    required this.categories,
    required this.query,
    this.onResultTap,
    this.onDocTap,
  });

  final List<ProjectData> projectResults;
  final List<BrandData> brandResults;
  final List<AssetData> assetResults;
  final List<DocumentData> docResults;
  final Map<String, String> docSubtitles;
  final List<dynamic> categories;
  final String query;
  final VoidCallback? onResultTap;
  final ValueChanged<DocumentData>? onDocTap;

  @override
  Widget build(BuildContext context) {
    if (projectResults.isEmpty &&
        brandResults.isEmpty &&
        assetResults.isEmpty &&
        docResults.isEmpty) {
      return _EmptyResults(query: query);
    }

    final iconByCategoryId = {
      for (final c in categories) c.id as String: c.iconName as String,
    };

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (brandResults.isNotEmpty) ...[
          const _SectionLabel('FIRMAS'),
          const SizedBox(height: AppSpacing.md),
          ...brandResults.map((brand) =>
              _BrandResultItem(brand: brand, onTap: onResultTap)),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (projectResults.isNotEmpty) ...[
          const _SectionLabel('PROYECTOS'),
          const SizedBox(height: AppSpacing.md),
          ...projectResults.map((project) =>
              _ProjectResultItem(project: project, onTap: onResultTap)),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (assetResults.isNotEmpty) ...[
          const _SectionLabel('ACTIVOS'),
          const SizedBox(height: AppSpacing.md),
          ...assetResults.map((asset) =>
              _AssetResultItem(asset: asset, onTap: onResultTap)),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (docResults.isNotEmpty) ...[
          const _SectionLabel('DOCUMENTOS'),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                for (int i = 0; i < docResults.length; i++) ...[
                  if (i > 0)
                    Container(
                      height: 0.5,
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  LhotseDocRow(
                    name: docResults[i].name,
                    date: _formatDocDate(docResults[i].date),
                    subtitle: docSubtitles[docResults[i].id],
                    icon: docCategoryIconByKey(
                      iconByCategoryId[docResults[i].categoryId] ?? 'fileText',
                    ),
                    onTap: () => onDocTap?.call(docResults[i]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }

  static String _formatDocDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('d MMM. yyyy', 'es_ES').format(date).toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        label,
        style: AppTypography.labelUppercaseMd.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _AssetResultItem extends StatelessWidget {
  const _AssetResultItem({required this.asset, this.onTap});

  final AssetData asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = asset.address ?? asset.location;
    final secondary = asset.address != null ? asset.location : null;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: asset.thumbnailImage != null
                ? LhotseImage(asset.thumbnailImage!)
                : Container(
                    color: AppColors.textPrimary.withValues(alpha: 0.05),
                    child: const Center(
                      child: PhosphorIcon(
                        PhosphorIconsThin.buildings,
                        size: 18,
                        color: AppColors.accentMuted,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary.toUpperCase(),
                  style: AppTypography.titleUppercase.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (secondary != null && secondary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    style: AppTypography.labelUppercaseSm.copyWith(
                      color: AppColors.accentMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
        context.push('/brands/${brand.id}', extra: brand);
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
                        style: AppTypography.annotation.copyWith(
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
                style: AppTypography.annotation
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
        context.push('/projects/${project.id}', extra: project);
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
                    style: AppTypography.titleUppercase.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        project.brand.toUpperCase(),
                        style: AppTypography.labelUppercaseSm.copyWith(
                          color: AppColors.textPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '·',
                          style: AppTypography.labelUppercaseSm.copyWith(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          project.location.toUpperCase(),
                          style: AppTypography.labelUppercaseSm.copyWith(
                            color: AppColors.accentMuted,
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
            style: AppTypography.editorialSubtitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Prueba con otro término de búsqueda',
            style: AppTypography.bodyReading.copyWith(
              color: AppColors.accentMuted,
            ),
          ),
        ],
      ),
    );
  }
}
