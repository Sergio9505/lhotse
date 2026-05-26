import 'package:freezed_annotation/freezed_annotation.dart';

import 'media_item.dart';

part 'content_block.freezed.dart';
part 'content_block.g.dart';

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

  /// Editorial carousel — accepts mixed images and videos. Each item is a
  /// `MediaItem` (`{ type: 'image'|'video', url }`); legacy items without
  /// `type` are treated as image by `MediaItem.fromJson`. Videos may be
  /// hosted on Supabase Storage or pasted as Bunny URLs/GUIDs from admin.
  const factory ContentBlock.gallery({
    required List<MediaItem> items,
  }) = GalleryBlock;

  const factory ContentBlock.video({
    required String url,
  }) = VideoBlock;

  /// In-flow CTA inserted by the operator. Renders as a black full-width
  /// button (clone of `_WebCta` in brand detail); tap opens the URL in the
  /// shared `EmbeddedWebViewScreen` so the user never leaves the app.
  /// `url` must be `https://…` — validated in the admin's Zod schema.
  const factory ContentBlock.cta({
    required String label,
    required String url,
  }) = CtaBlock;

  factory ContentBlock.fromJson(Map<String, Object?> json) =>
      _$ContentBlockFromJson(json);
}
