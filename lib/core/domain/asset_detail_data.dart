/// Full asset detail model: thumbnail, address (title), brand (from owning
/// project), gallery, and floor plan. Fetched via `assetByIdProvider`.
///
/// Separate from the lightweight `AssetData` used by the search screen so
/// that screen does not pay the cost of the project/brands join.
final class AssetDetailData {
  const AssetDetailData({
    required this.id,
    required this.address,
    required this.galleryImages,
    required this.useLightOverlay,
    this.thumbnailImage,
    this.city,
    this.floorPlanUrl,
    this.brandName,
  });

  final String id;
  final String? thumbnailImage;
  final String address;
  final String? city;
  final List<String> galleryImages;
  final String? floorPlanUrl;
  final bool useLightOverlay;

  /// Brand name from the project that owns this asset (projects → brands join).
  final String? brandName;

  /// Parses a row returned by querying `projects` with embedded `assets` and
  /// `brands`:
  ///   from('projects')
  ///     .select('name, brands(name), assets!inner(id, thumbnail_image,
  ///              address, city, gallery_images, floor_plan_url,
  ///              use_light_overlay)')
  ///     .eq('asset_id', assetId)
  factory AssetDetailData.fromProjectRow(Map<String, dynamic> row) {
    final assetJson = row['assets'] as Map<String, dynamic>;
    final brandsJson = row['brands'] as Map<String, dynamic>?;

    final rawGallery = assetJson['gallery_images'];
    final gallery =
        rawGallery is List ? List<String>.from(rawGallery) : const <String>[];

    return AssetDetailData(
      id: assetJson['id'] as String,
      thumbnailImage: assetJson['thumbnail_image'] as String?,
      address: assetJson['address'] as String? ?? '',
      city: assetJson['city'] as String?,
      galleryImages: gallery,
      floorPlanUrl: assetJson['floor_plan_url'] as String?,
      useLightOverlay: assetJson['use_light_overlay'] as bool? ?? true,
      brandName: brandsJson?['name'] as String?,
    );
  }
}
