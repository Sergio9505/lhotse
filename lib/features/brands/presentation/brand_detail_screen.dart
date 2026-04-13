import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_notification_bell.dart';

class BrandDetailScreen extends StatelessWidget {
  const BrandDetailScreen({super.key, required this.brandId});

  final String brandId;

  @override
  Widget build(BuildContext context) {
    final brand = mockBrands.firstWhere((b) => b.id == brandId);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── Header ───────────────────────────────────────────────
          _BrandDetailHeader(topPadding: topPadding),

          // ─── Content ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        0,
                      ),
                      child: _BrandLogo(brand: brand),
                    ),

                    // Tagline
                    if (brand.tagline != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Text(
                          brand.tagline!,
                          style: AppTypography.headingMedium.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.3,
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

                    // Reference image
                    const SizedBox(height: AppSpacing.xxl),
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: LhotseImage(brand.coverImageUrl),
                    ),

                    // CTA
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xxl,
                        AppSpacing.lg,
                        bottomPadding + AppSpacing.xl,
                      ),
                      child: _WebCta(websiteUrl: brand.websiteUrl),
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

// ─── Header ─────────────────────────────────────────────────────────────────

class _BrandDetailHeader extends StatelessWidget {
  const _BrandDetailHeader({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        topPadding + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          LhotseBackButton.onSurface(),
          Expanded(
            child: Center(
              child: Text(
                'FIRMAS',
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const LhotseNotificationBell(),
        ],
      ),
    );
  }
}

// ─── Logo ────────────────────────────────────────────────────────────────────

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.brand});

  final BrandData brand;

  @override
  Widget build(BuildContext context) {
    if (brand.logoAsset != null) {
      return SvgPicture.asset(
        brand.logoAsset!,
        height: 56,
        colorFilter: const ColorFilter.mode(
          AppColors.textPrimary,
          BlendMode.srcIn,
        ),
      );
    }
    return Text(
      brand.name.toUpperCase(),
      style: AppTypography.headingLarge.copyWith(
        color: AppColors.textPrimary,
      ),
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
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.6,
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
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.6,
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
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textOnDark,
              letterSpacing: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}
