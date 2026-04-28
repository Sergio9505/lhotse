import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/brands_provider.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_image.dart';

class BrandDetailScreen extends ConsumerStatefulWidget {
  const BrandDetailScreen({
    super.key,
    required this.brandId,
    this.initialBrand,
  });

  final String brandId;

  /// Pre-loaded snapshot from the caller (list/grid) so the first frame has
  /// all the data needed to render. No Hero here today, but keeping the
  /// pattern consistent with project/news details so future shared-element
  /// work doesn't have to retrofit.
  final BrandData? initialBrand;

  @override
  ConsumerState<BrandDetailScreen> createState() => _BrandDetailScreenState();
}

class _BrandDetailScreenState extends ConsumerState<BrandDetailScreen> {
  final _scrollController = ScrollController();
  bool _showLogoInHeader = false;

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
    // Logo sits ~100px below the top of the scroll area; show header logo once it scrolls past
    final show = _scrollController.offset > 100;
    if (show != _showLogoInHeader) setState(() => _showLogoInHeader = show);
  }

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(brandByIdProvider(widget.brandId)).valueOrNull ??
        widget.initialBrand;
    final topPadding = MediaQuery.of(context).padding.top;

    if (brand == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── Header ───────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm,
              topPadding + AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                LhotseBackButton.onSurface(),
                Expanded(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _showLogoInHeader ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_showLogoInHeader,
                        child: _BrandLogoHeader(brand: brand),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 44), // balance back button
              ],
            ),
          ),

          // ─── Content + floating CTA ───────────────────────────────
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo — quiet identity mark
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          0,
                        ),
                        child: _BrandLogo(brand: brand),
                      ),

                      // Tagline — editorial hero statement
                      if (brand.tagline != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          child: Text(
                            brand.tagline!,
                            style: AppTypography.editorialSubtitle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],

                      // Description
                      if (brand.description != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          child: _BrandDescription(brand: brand),
                        ),
                      ],

                      // Cover image — full-bleed
                      const SizedBox(height: AppSpacing.xxl),
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: LhotseImage(brand.coverImageUrl),
                      ),

                      // Space so last content clears the floating CTA
                      // CTA height (~52) + bottom gap (lg=24) + breathing room
                      const SizedBox(height: 96),
                    ],
                  ),
                ),

                // Floating CTA — no background, just the black button
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: _WebCta(websiteUrl: brand.websiteUrl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logo (header, compact) ──────────────────────────────────────────────────

class _BrandLogoHeader extends StatelessWidget {
  const _BrandLogoHeader({required this.brand});
  final BrandData brand;
  static const _filter = ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn);

  @override
  Widget build(BuildContext context) {
    final logo = brand.logoAsset;
    if (logo != null) {
      return SizedBox(
        width: 80,
        height: 20,
        child: logo.startsWith('http')
            ? SvgPicture.network(logo, fit: BoxFit.contain, colorFilter: _filter)
            : SvgPicture.asset(logo, fit: BoxFit.contain, colorFilter: _filter),
      );
    }
    return Text(
      brand.name.toUpperCase(),
      style: AppTypography.titleUppercase.copyWith(color: AppColors.textPrimary),
    );
  }
}

// ─── Logo (content) ──────────────────────────────────────────────────────────

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.brand});
  final BrandData brand;
  static const _filter = ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn);

  @override
  Widget build(BuildContext context) {
    final logo = brand.logoAsset;
    if (logo != null) {
      return SizedBox(
        width: 160,
        height: 40,
        child: Align(
          alignment: Alignment.centerLeft,
          child: logo.startsWith('http')
              ? SvgPicture.network(logo, fit: BoxFit.contain, colorFilter: _filter)
              : SvgPicture.asset(logo, fit: BoxFit.contain, colorFilter: _filter),
        ),
      );
    }
    return Text(
      brand.name.toUpperCase(),
      style: AppTypography.titleUppercase.copyWith(color: AppColors.textPrimary),
    );
  }
}

// ─── Description ─────────────────────────────────────────────────────────────

class _BrandDescription extends StatelessWidget {
  const _BrandDescription({required this.brand});

  final BrandData brand;

  @override
  Widget build(BuildContext context) {
    final raw = brand.description!;
    final modelName = brand.businessModel.displayName;

    // Split into paragraphs and bold the business model name within each
    final paragraphs = raw.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((para) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: paragraphs.last == para ? 0 : AppSpacing.sm,
          ),
          child: _buildRichParagraph(para, modelName),
        );
      }).toList(),
    );
  }

  Widget _buildRichParagraph(String text, String modelName) {
    final parts = text.split(modelName);
    if (parts.length == 1) {
      return Text(
        text,
        style: AppTypography.bodyReading.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i]));
      }
      if (i < parts.length - 1) {
        spans.add(TextSpan(
          text: modelName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ));
      }
    }

    return RichText(
      text: TextSpan(
        style: AppTypography.bodyReading.copyWith(
          color: AppColors.textSecondary,
        ),
        children: spans,
      ),
    );
  }
}

// ─── CTA ─────────────────────────────────────────────────────────────────────

class _WebCta extends StatelessWidget {
  const _WebCta({required this.websiteUrl});

  final String? websiteUrl;

  Future<void> _launch() async {
    if (websiteUrl == null) return;
    final uri = Uri.parse(websiteUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launch,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: AppColors.primary,
        child: Center(
          child: Text(
            'VISITAR WEB',
            style: AppTypography.labelUppercaseMd.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
        ),
      ),
    );
  }
}
