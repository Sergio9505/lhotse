// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_block.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ImageItem {

 String get url; String? get alt;
/// Create a copy of ImageItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageItemCopyWith<ImageItem> get copyWith => _$ImageItemCopyWithImpl<ImageItem>(this as ImageItem, _$identity);

  /// Serializes this ImageItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageItem&&(identical(other.url, url) || other.url == url)&&(identical(other.alt, alt) || other.alt == alt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,alt);

@override
String toString() {
  return 'ImageItem(url: $url, alt: $alt)';
}


}

/// @nodoc
abstract mixin class $ImageItemCopyWith<$Res>  {
  factory $ImageItemCopyWith(ImageItem value, $Res Function(ImageItem) _then) = _$ImageItemCopyWithImpl;
@useResult
$Res call({
 String url, String? alt
});




}
/// @nodoc
class _$ImageItemCopyWithImpl<$Res>
    implements $ImageItemCopyWith<$Res> {
  _$ImageItemCopyWithImpl(this._self, this._then);

  final ImageItem _self;
  final $Res Function(ImageItem) _then;

/// Create a copy of ImageItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? alt = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,alt: freezed == alt ? _self.alt : alt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageItem].
extension ImageItemPatterns on ImageItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageItem value)  $default,){
final _that = this;
switch (_that) {
case _ImageItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageItem value)?  $default,){
final _that = this;
switch (_that) {
case _ImageItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String? alt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageItem() when $default != null:
return $default(_that.url,_that.alt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String? alt)  $default,) {final _that = this;
switch (_that) {
case _ImageItem():
return $default(_that.url,_that.alt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String? alt)?  $default,) {final _that = this;
switch (_that) {
case _ImageItem() when $default != null:
return $default(_that.url,_that.alt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImageItem implements ImageItem {
  const _ImageItem({required this.url, this.alt});
  factory _ImageItem.fromJson(Map<String, dynamic> json) => _$ImageItemFromJson(json);

@override final  String url;
@override final  String? alt;

/// Create a copy of ImageItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageItemCopyWith<_ImageItem> get copyWith => __$ImageItemCopyWithImpl<_ImageItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageItem&&(identical(other.url, url) || other.url == url)&&(identical(other.alt, alt) || other.alt == alt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,alt);

@override
String toString() {
  return 'ImageItem(url: $url, alt: $alt)';
}


}

/// @nodoc
abstract mixin class _$ImageItemCopyWith<$Res> implements $ImageItemCopyWith<$Res> {
  factory _$ImageItemCopyWith(_ImageItem value, $Res Function(_ImageItem) _then) = __$ImageItemCopyWithImpl;
@override @useResult
$Res call({
 String url, String? alt
});




}
/// @nodoc
class __$ImageItemCopyWithImpl<$Res>
    implements _$ImageItemCopyWith<$Res> {
  __$ImageItemCopyWithImpl(this._self, this._then);

  final _ImageItem _self;
  final $Res Function(_ImageItem) _then;

/// Create a copy of ImageItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? alt = freezed,}) {
  return _then(_ImageItem(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,alt: freezed == alt ? _self.alt : alt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

ContentBlock _$ContentBlockFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'heading':
          return HeadingBlock.fromJson(
            json
          );
                case 'text':
          return TextBlock.fromJson(
            json
          );
                case 'image':
          return ImageBlock.fromJson(
            json
          );
                case 'gallery':
          return GalleryBlock.fromJson(
            json
          );
                case 'video':
          return VideoBlock.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'ContentBlock',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$ContentBlock {



  /// Serializes this ContentBlock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentBlock);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ContentBlock()';
}


}

/// @nodoc
class $ContentBlockCopyWith<$Res>  {
$ContentBlockCopyWith(ContentBlock _, $Res Function(ContentBlock) __);
}


/// Adds pattern-matching-related methods to [ContentBlock].
extension ContentBlockPatterns on ContentBlock {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HeadingBlock value)?  heading,TResult Function( TextBlock value)?  text,TResult Function( ImageBlock value)?  image,TResult Function( GalleryBlock value)?  gallery,TResult Function( VideoBlock value)?  video,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HeadingBlock() when heading != null:
return heading(_that);case TextBlock() when text != null:
return text(_that);case ImageBlock() when image != null:
return image(_that);case GalleryBlock() when gallery != null:
return gallery(_that);case VideoBlock() when video != null:
return video(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HeadingBlock value)  heading,required TResult Function( TextBlock value)  text,required TResult Function( ImageBlock value)  image,required TResult Function( GalleryBlock value)  gallery,required TResult Function( VideoBlock value)  video,}){
final _that = this;
switch (_that) {
case HeadingBlock():
return heading(_that);case TextBlock():
return text(_that);case ImageBlock():
return image(_that);case GalleryBlock():
return gallery(_that);case VideoBlock():
return video(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HeadingBlock value)?  heading,TResult? Function( TextBlock value)?  text,TResult? Function( ImageBlock value)?  image,TResult? Function( GalleryBlock value)?  gallery,TResult? Function( VideoBlock value)?  video,}){
final _that = this;
switch (_that) {
case HeadingBlock() when heading != null:
return heading(_that);case TextBlock() when text != null:
return text(_that);case ImageBlock() when image != null:
return image(_that);case GalleryBlock() when gallery != null:
return gallery(_that);case VideoBlock() when video != null:
return video(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  heading,TResult Function( String text)?  text,TResult Function( String url,  String? alt)?  image,TResult Function( List<ImageItem> items)?  gallery,TResult Function( String url)?  video,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HeadingBlock() when heading != null:
return heading(_that.text);case TextBlock() when text != null:
return text(_that.text);case ImageBlock() when image != null:
return image(_that.url,_that.alt);case GalleryBlock() when gallery != null:
return gallery(_that.items);case VideoBlock() when video != null:
return video(_that.url);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  heading,required TResult Function( String text)  text,required TResult Function( String url,  String? alt)  image,required TResult Function( List<ImageItem> items)  gallery,required TResult Function( String url)  video,}) {final _that = this;
switch (_that) {
case HeadingBlock():
return heading(_that.text);case TextBlock():
return text(_that.text);case ImageBlock():
return image(_that.url,_that.alt);case GalleryBlock():
return gallery(_that.items);case VideoBlock():
return video(_that.url);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  heading,TResult? Function( String text)?  text,TResult? Function( String url,  String? alt)?  image,TResult? Function( List<ImageItem> items)?  gallery,TResult? Function( String url)?  video,}) {final _that = this;
switch (_that) {
case HeadingBlock() when heading != null:
return heading(_that.text);case TextBlock() when text != null:
return text(_that.text);case ImageBlock() when image != null:
return image(_that.url,_that.alt);case GalleryBlock() when gallery != null:
return gallery(_that.items);case VideoBlock() when video != null:
return video(_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class HeadingBlock implements ContentBlock {
  const HeadingBlock({required this.text, final  String? $type}): $type = $type ?? 'heading';
  factory HeadingBlock.fromJson(Map<String, dynamic> json) => _$HeadingBlockFromJson(json);

 final  String text;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeadingBlockCopyWith<HeadingBlock> get copyWith => _$HeadingBlockCopyWithImpl<HeadingBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HeadingBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeadingBlock&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'ContentBlock.heading(text: $text)';
}


}

/// @nodoc
abstract mixin class $HeadingBlockCopyWith<$Res> implements $ContentBlockCopyWith<$Res> {
  factory $HeadingBlockCopyWith(HeadingBlock value, $Res Function(HeadingBlock) _then) = _$HeadingBlockCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$HeadingBlockCopyWithImpl<$Res>
    implements $HeadingBlockCopyWith<$Res> {
  _$HeadingBlockCopyWithImpl(this._self, this._then);

  final HeadingBlock _self;
  final $Res Function(HeadingBlock) _then;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(HeadingBlock(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class TextBlock implements ContentBlock {
  const TextBlock({required this.text, final  String? $type}): $type = $type ?? 'text';
  factory TextBlock.fromJson(Map<String, dynamic> json) => _$TextBlockFromJson(json);

 final  String text;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextBlockCopyWith<TextBlock> get copyWith => _$TextBlockCopyWithImpl<TextBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TextBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextBlock&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'ContentBlock.text(text: $text)';
}


}

/// @nodoc
abstract mixin class $TextBlockCopyWith<$Res> implements $ContentBlockCopyWith<$Res> {
  factory $TextBlockCopyWith(TextBlock value, $Res Function(TextBlock) _then) = _$TextBlockCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$TextBlockCopyWithImpl<$Res>
    implements $TextBlockCopyWith<$Res> {
  _$TextBlockCopyWithImpl(this._self, this._then);

  final TextBlock _self;
  final $Res Function(TextBlock) _then;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(TextBlock(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ImageBlock implements ContentBlock {
  const ImageBlock({required this.url, this.alt, final  String? $type}): $type = $type ?? 'image';
  factory ImageBlock.fromJson(Map<String, dynamic> json) => _$ImageBlockFromJson(json);

 final  String url;
 final  String? alt;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageBlockCopyWith<ImageBlock> get copyWith => _$ImageBlockCopyWithImpl<ImageBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageBlock&&(identical(other.url, url) || other.url == url)&&(identical(other.alt, alt) || other.alt == alt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,alt);

@override
String toString() {
  return 'ContentBlock.image(url: $url, alt: $alt)';
}


}

/// @nodoc
abstract mixin class $ImageBlockCopyWith<$Res> implements $ContentBlockCopyWith<$Res> {
  factory $ImageBlockCopyWith(ImageBlock value, $Res Function(ImageBlock) _then) = _$ImageBlockCopyWithImpl;
@useResult
$Res call({
 String url, String? alt
});




}
/// @nodoc
class _$ImageBlockCopyWithImpl<$Res>
    implements $ImageBlockCopyWith<$Res> {
  _$ImageBlockCopyWithImpl(this._self, this._then);

  final ImageBlock _self;
  final $Res Function(ImageBlock) _then;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,Object? alt = freezed,}) {
  return _then(ImageBlock(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,alt: freezed == alt ? _self.alt : alt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GalleryBlock implements ContentBlock {
  const GalleryBlock({required final  List<ImageItem> items, final  String? $type}): _items = items,$type = $type ?? 'gallery';
  factory GalleryBlock.fromJson(Map<String, dynamic> json) => _$GalleryBlockFromJson(json);

 final  List<ImageItem> _items;
 List<ImageItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GalleryBlockCopyWith<GalleryBlock> get copyWith => _$GalleryBlockCopyWithImpl<GalleryBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GalleryBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryBlock&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'ContentBlock.gallery(items: $items)';
}


}

/// @nodoc
abstract mixin class $GalleryBlockCopyWith<$Res> implements $ContentBlockCopyWith<$Res> {
  factory $GalleryBlockCopyWith(GalleryBlock value, $Res Function(GalleryBlock) _then) = _$GalleryBlockCopyWithImpl;
@useResult
$Res call({
 List<ImageItem> items
});




}
/// @nodoc
class _$GalleryBlockCopyWithImpl<$Res>
    implements $GalleryBlockCopyWith<$Res> {
  _$GalleryBlockCopyWithImpl(this._self, this._then);

  final GalleryBlock _self;
  final $Res Function(GalleryBlock) _then;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(GalleryBlock(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ImageItem>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class VideoBlock implements ContentBlock {
  const VideoBlock({required this.url, final  String? $type}): $type = $type ?? 'video';
  factory VideoBlock.fromJson(Map<String, dynamic> json) => _$VideoBlockFromJson(json);

 final  String url;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoBlockCopyWith<VideoBlock> get copyWith => _$VideoBlockCopyWithImpl<VideoBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoBlock&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url);

@override
String toString() {
  return 'ContentBlock.video(url: $url)';
}


}

/// @nodoc
abstract mixin class $VideoBlockCopyWith<$Res> implements $ContentBlockCopyWith<$Res> {
  factory $VideoBlockCopyWith(VideoBlock value, $Res Function(VideoBlock) _then) = _$VideoBlockCopyWithImpl;
@useResult
$Res call({
 String url
});




}
/// @nodoc
class _$VideoBlockCopyWithImpl<$Res>
    implements $VideoBlockCopyWith<$Res> {
  _$VideoBlockCopyWithImpl(this._self, this._then);

  final VideoBlock _self;
  final $Res Function(VideoBlock) _then;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,}) {
  return _then(VideoBlock(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
