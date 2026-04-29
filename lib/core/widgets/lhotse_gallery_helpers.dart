import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../domain/media_item.dart';
import '../theme/app_theme.dart';
import 'lhotse_bottom_sheet.dart';
import 'lhotse_image.dart';
import '../../features/home/presentation/widgets/fullscreen_video_player.dart';

/// Opens a bottom sheet with all gallery items (images and videos) in a
/// vertical scroll. Tapping an image opens a pinch-to-zoom viewer; tapping a
/// video opens a fullscreen player.
void showAllGallery(
    BuildContext context, String title, List<MediaItem> items) {
  showLhotseBottomSheet(
    context: context,
    title: title,
    itemCount: items.length,
    listPadding: EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      MediaQuery.of(context).padding.bottom + AppSpacing.md,
    ),
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
    itemBuilder: (context, i) {
      final item = items[i];
      return GestureDetector(
        onTap: () => showFullMedia(context, item),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: item.type == MediaType.image
              ? LhotseImage(item.url)
              : VideoThumbnailTile(url: item.url),
        ),
      );
    },
  );
}

/// Opens an image fullscreen viewer or a video player depending on item type.
void showFullMedia(BuildContext context, MediaItem item) {
  if (item.type == MediaType.image) {
    showFullImage(context, item.url);
  } else {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FullscreenVideoPlayer(
          videoUrl: item.url,
          posterUrl: '',
        ),
      ),
    );
  }
}

/// Opens a full-screen image viewer with InteractiveViewer (pinch to zoom).
void showFullImage(BuildContext context, String imageUrl) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        final topPadding = MediaQuery.of(context).padding.top;
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Opacity(
            opacity: animation.value,
            child: child,
          ),
          child: Scaffold(
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
                            0,
                            topPadding + kToolbarHeight,
                            0,
                            bottomPadding + AppSpacing.lg,
                          ),
                          child: LhotseImage(imageUrl, fit: BoxFit.contain),
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
                          color: AppColors.textPrimary
                              .withValues(alpha: 0.08),
                          child: const PhosphorIcon(
                            PhosphorIconsThin.x,
                            color: AppColors.textPrimary,
                            size: 20,
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

/// Simple dark tile with a film icon used as video placeholder in galleries.
class VideoThumbnailTile extends StatelessWidget {
  const VideoThumbnailTile({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: PhosphorIcon(
          PhosphorIconsThin.filmSlate,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}
