// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_block.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ImageItem _$ImageItemFromJson(Map<String, dynamic> json) =>
    _ImageItem(url: json['url'] as String, alt: json['alt'] as String?);

Map<String, dynamic> _$ImageItemToJson(_ImageItem instance) =>
    <String, dynamic>{'url': instance.url, 'alt': instance.alt};

HeadingBlock _$HeadingBlockFromJson(Map<String, dynamic> json) =>
    HeadingBlock(text: json['text'] as String, $type: json['type'] as String?);

Map<String, dynamic> _$HeadingBlockToJson(HeadingBlock instance) =>
    <String, dynamic>{'text': instance.text, 'type': instance.$type};

TextBlock _$TextBlockFromJson(Map<String, dynamic> json) =>
    TextBlock(text: json['text'] as String, $type: json['type'] as String?);

Map<String, dynamic> _$TextBlockToJson(TextBlock instance) => <String, dynamic>{
  'text': instance.text,
  'type': instance.$type,
};

ImageBlock _$ImageBlockFromJson(Map<String, dynamic> json) => ImageBlock(
  url: json['url'] as String,
  alt: json['alt'] as String?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ImageBlockToJson(ImageBlock instance) =>
    <String, dynamic>{
      'url': instance.url,
      'alt': instance.alt,
      'type': instance.$type,
    };

GalleryBlock _$GalleryBlockFromJson(Map<String, dynamic> json) => GalleryBlock(
  items: (json['items'] as List<dynamic>)
      .map((e) => ImageItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$GalleryBlockToJson(GalleryBlock instance) =>
    <String, dynamic>{'items': instance.items, 'type': instance.$type};

VideoBlock _$VideoBlockFromJson(Map<String, dynamic> json) =>
    VideoBlock(url: json['url'] as String, $type: json['type'] as String?);

Map<String, dynamic> _$VideoBlockToJson(VideoBlock instance) =>
    <String, dynamic>{'url': instance.url, 'type': instance.$type};
