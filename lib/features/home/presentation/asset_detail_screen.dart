import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/asset_detail_provider.dart';
import '../../../core/domain/asset_data.dart';
import '../../../core/domain/asset_detail_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_section_label.dart';

const _kMaxVisibleGallery = 5;

/// Detail view for a single asset. Shows the asset hero image, address as
/// editorial title, brand+city byline (from the owning project), gallery, and
/// floor plan. No specs, no description — strictly the editorial scope.
class AssetDetailScreen extends ConsumerStatefulWidget {
  const AssetDetailScreen({
    super.key,
    required this.assetId,
    this.initialAsset,
  });

  final String assetId;

  /// Lightweight snapshot from the feed. Provides thumbnail + address for
  /// first-frame Hero rendering while `assetByIdProvider` resolves.
  final AssetData? initialAsset;

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen> {
  final _scrollController = ScrollController();
  bool _heroGone = false;
  bool _showCollapsedTitle = false;
  double _heroHeight = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final heroThreshold = _heroHeight - kToolbarHeight;
    final heroGone = offset >= heroThreshold;
    final titleThreshold = _heroHeight + 50.0;
    final showTitle = offset >= titleThreshold;

    if (heroGone != _heroGone || showTitle != _showCollapsedTitle) {
      setState(() {
        _heroGone = heroGone;
        _showCollapsedTitle = showTitle;
      });
    }
  }

  /// Builds a skeleton `AssetDetailData` from the lightweight initial asset so
  /// the Hero image and address title render on the very first frame — before
  /// `assetByIdProvider` resolves. Gallery and floor plan stay hidden until
  /// the provider fills them in.
  AssetDetailData? _skeletonFromInitial() {
    final a = widget.initialAsset;
    if (a == null) return null;
    return AssetDetailData(
      id: a.id,
      thumbnailImage: a.thumbnailImage,
      address: a.address ?? '',
      city: a.city,
      galleryImages: const [],
      floorPlanUrl: null,
      useLightOverlay: true,
      brandName: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(assetByIdProvider(widget.assetId));
    final detail = detailAsync.valueOrNull ?? _skeletonFromInitial();

    if (detail == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: detailAsync.isLoading
              ? const CircularProgressIndicator(strokeWidth: 1.5)
              : Text(
                  'Activo no encontrado',
                  style: AppTypography.bodyRow.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    _heroHeight = MediaQuery.of(context).size.height * 0.55;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _heroGone
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // =========================================================
            // 1. HERO
            // =========================================================
            SliverAppBar(
              pinned: true,
              expandedHeight: _heroHeight,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: _heroGone
                  ? const LhotseBackButton.onSurface()
                  : LhotseBackButton.overImage(
                      useLightOverlay: detail.useLightOverlay,
                    ),
              actions: const [SizedBox(width: 44)],
              centerTitle: true,
              title: AnimatedOpacity(
                opacity: _showCollapsedTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      detail.address.toUpperCase(),
                      style: AppTypography.titleUppercase.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (detail.brandName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail.brandName!.toUpperCase(),
                        style: AppTypography.labelUppercaseSm.copyWith(
                          color: AppColors.accentMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'asset-hero-${detail.id}',
                      child: LhotseImage(detail.thumbnailImage ?? ''),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [Color(0x66000000), Colors.transparent],
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0, 0.2),
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x8C1F1916),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =========================================================
            // 2. IDENTITY
            // =========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.address,
                      style: AppTypography.editorialHero.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: AppTypography.wordmarkByline,
                        children: [
                          if (detail.brandName != null &&
                              detail.brandName!.isNotEmpty) ...[
                            TextSpan(
                              text: detail.brandName!.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (detail.city != null &&
                                detail.city!.isNotEmpty)
                              TextSpan(
                                text: '  ·  ',
                                style: TextStyle(
                                  color: AppColors.textPrimary
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                          ],
                          if (detail.city != null && detail.city!.isNotEmpty)
                            TextSpan(
                              text: detail.city!,
                              style: AppTypography.annotation.copyWith(
                                color: AppColors.accentMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =========================================================
            // 3. GALERÍA
            // =========================================================
            if (detail.galleryImages.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      child: Row(
                        children: [
                          Text(
                            'GALERÍA',
                            style: AppTypography.sectionLabel.copyWith(
                              color: AppColors.accentMuted,
                            ),
                          ),
                          if (detail.galleryImages.length >
                              _kMaxVisibleGallery) ...[
                            const SizedBox(width: AppSpacing.sm),
                            GestureDetector(
                              onTap: () => showAllGallery(
                                  context, 'GALERÍA', detail.galleryImages),
                              child: const PhosphorIcon(
                                PhosphorIconsThin.arrowUpRight,
                                size: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        itemCount:
                            detail.galleryImages.length > _kMaxVisibleGallery
                                ? _kMaxVisibleGallery
                                : detail.galleryImages.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () =>
                              showFullImage(context, detail.galleryImages[i]),
                          child: Container(
                            width: screenWidth * 0.75,
                            decoration: const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: LhotseImage(detail.galleryImages[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // =========================================================
            // 4. PLANO
            // =========================================================
            if (detail.floorPlanUrl != null)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    const LhotseSectionLabel(label: 'PLANO'),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      child: GestureDetector(
                        onTap: () =>
                            _showFloorPlan(context, detail.floorPlanUrl!),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg),
                          color: AppColors.background,
                          child: Stack(
                            children: [
                              Center(
                                child: LhotseImage(
                                  detail.floorPlanUrl!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: PhosphorIcon(
                                  PhosphorIconsThin.arrowsOut,
                                  color: AppColors.accentMuted,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom safe-area spacing
            SliverToBoxAdapter(
              child: SizedBox(height: bottomPadding + AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floor plan fullscreen ─────────────────────────────────────────────────────

void _showFloorPlan(BuildContext context, String url) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        final topPadding = MediaQuery.of(context).padding.top;
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) =>
              Opacity(opacity: animation.value, child: child),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            backgroundColor: AppColors.background,
            body: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        maxScale: 4.0,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            topPadding + kToolbarHeight,
                            AppSpacing.lg,
                            bottomPadding + AppSpacing.lg,
                          ),
                          child: Image.network(url, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    Positioned(
                      top: topPadding + AppSpacing.md,
                      right: AppSpacing.lg,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          color:
                              AppColors.textPrimary.withValues(alpha: 0.08),
                          child: const PhosphorIcon(
                            PhosphorIconsThin.x,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
