import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_block.freezed.dart';
part 'content_block.g.dart';

/// Single image inside a `gallery` block. Distinct from `MediaItem`
/// (which is the mixed image|video model used for the post-cierre gallery
/// and hero media) — gallery blocks accept images only.
@freezed
abstract class ImageItem with _$ImageItem {
  const factory ImageItem({
    required String url,
    String? alt,
  }) = _ImageItem;

  factory ImageItem.fromJson(Map<String, Object?> json) =>
      _$ImageItemFromJson(json);
}

/// Editorial body of a project detail. Renders as a vertical stack of
/// typed blocks (heading / text / image / gallery / video) in fixed
/// tokens — the admin only decides which blocks and in which order.
///
/// Persisted as a jsonb array on `projects.content`. Discriminator is the
/// JSON field `type` (snake_case: 'heading', 'text', 'image', 'gallery',
/// 'video').
@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
sealed class ContentBlock with _$ContentBlock {
  const factory ContentBlock.heading({
    required String text,
  }) = HeadingBlock;

  const factory ContentBlock.text({
    required String text,
  }) = TextBlock;

  const factory ContentBlock.image({
    required String url,
    String? alt,
  }) = ImageBlock;

  const factory ContentBlock.gallery({
    required List<ImageItem> items,
  }) = GalleryBlock;

  const factory ContentBlock.video({
    required String url,
  }) = VideoBlock;

  factory ContentBlock.fromJson(Map<String, Object?> json) =>
      _$ContentBlockFromJson(json);
}
