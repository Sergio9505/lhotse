import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/media_item.dart';
import '../../../../core/domain/project_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_bottom_sheet.dart';
import '../../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../../core/widgets/lhotse_image.dart';
import '../../../profile/data/user_requests_provider.dart';

/// Shows the "Solicitar información" bottom sheet for a project currently
/// in fundraising (`is_fundraising_open = true`). The CTA submits a
/// `user_requests` row with `type = 'project_info'` + `project_id` on first
/// tap and reflects "SOLICITUD EN ESTUDIO" on subsequent opens while a
/// non-declined request exists for this (user, project) pair. Mirrors the
/// state-aware shape of `vip_lock_sheet.dart`.
///
/// Layout (editorial, three zones):
///   1. Title — `project.name` in `editorialTitle` (provided by
///      `LhotseBottomSheetBody`).
///   2. Render carousel — edge-to-edge horizontal `ListView` of
///      `project.renderMedia` (images + videos from the admin "Renders y
///      mockups" section). Cards 75% screen width, infinite loop when ≥2.
///      Falls back to the `imageUrl` cover (3:2) when the project has no
///      renders yet.
///   3. Subtitle — `project.tagline` in romana sentence-case
///      (`bodyReading` 14pt `textSecondary`), no italic. Acts as a lead,
///      not as decoration — the wealth voice (JPM Private Bank, Sotheby's
///      auction lot) keeps post-title prose in roman type.
///   4. CTA — full-width black 52pt button.
void showRequestInfoSheet(BuildContext context, ProjectData project) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => LhotseBottomSheetBody(
      title: project.name,
      titleStyle: AppTypography.editorialTitle.copyWith(
        color: AppColors.textPrimary,
      ),
      bodyBuilder: (bottomPadding) => _RequestInfoSheetBody(
        project: project,
        bottomPadding: bottomPadding,
      ),
    ),
  );
}

class _RequestInfoSheetBody extends ConsumerWidget {
  const _RequestInfoSheetBody({
    required this.project,
    required this.bottomPadding,
  });

  final ProjectData project;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exists = ref
            .watch(userProjectRequestExistsProvider(project.id))
            .valueOrNull ??
        false;

    final label = exists ? 'SOLICITUD EN ESTUDIO' : 'SOLICITAR INFORMACIÓN';

    Future<void> onTap() async {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      try {
        await submitUserRequest(
          ref,
          UserRequestType.projectInfo,
          projectId: project.id,
        );
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Solicitud recibida. Te contactaremos pronto.'),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo enviar la solicitud. Inténtalo de nuevo.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    final hasTagline = project.tagline.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xl + bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Zone 1: render carousel (edge-to-edge) ──────────────────────
          _RequestInfoCarousel(
            items: project.renderMedia,
            fallbackImageUrl: project.imageUrl,
          ),

          // ── Zone 2: tagline subtitle ───────────────────────────────────
          // Caption-level gap when present; section-break gap to the CTA
          // otherwise (handled below).
          if (hasTagline) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                project.tagline,
                style: AppTypography.bodyReading.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],

          // ── Zone 3: CTA ────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: exists ? null : onTap,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: exists ? 0.6 : 1.0,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  color: AppColors.primary,
                  child: Text(
                    label,
                    style: AppTypography.labelUppercaseMd.copyWith(
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal render carousel. Edge-to-edge layout: the parent Column does
/// not pad horizontally, the inner `ListView` does — so the first card
/// aligns with the title's left edge (24pt) while the next card peeks past
/// the right edge of the screen.
///
/// Clones the canonical `_GalleryView` pattern from
/// `project_content_renderer.dart`: 200pt height, 75% screen width cards,
/// infinite forward loop when N ≥ 2, no dots indicator, tap → fullscreen
/// `showMediaGallery` at the tapped index.
///
/// Falls back to an AspectRatio(3/2) cover when the project has no renders
/// (early in the lifecycle, before the admin uploads them).
class _RequestInfoCarousel extends StatelessWidget {
  const _RequestInfoCarousel({
    required this.items,
    required this.fallbackImageUrl,
  });

  final List<MediaItem> items;
  final String? fallbackImageUrl;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      final cover = fallbackImageUrl;
      if (cover == null || cover.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: LhotseImage(cover),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 200,
      child: ListView.separated(
        key: PageStorageKey('request-info-carousel-${identityHashCode(items)}'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => showMediaGallery(
              context,
              items: items,
              initialIndex: i,
            ),
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
              child: item.type == MediaType.image
                  ? LhotseImage(item.url)
                  : VideoThumbnailTile(url: item.url),
            ),
          );
        },
      ),
    );
  }
}
