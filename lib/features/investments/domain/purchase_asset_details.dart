import '../../../core/domain/asset_info.dart';
import '../../../core/domain/media_item.dart';

/// Per-asset data for the direct purchase detail screen's ACTIVO tab.
/// Loaded lazily via `purchaseAssetDetailProvider(assetId)`.
///
/// An asset may be owned sequentially by multiple investors; this view is
/// not filtered by user.
class PurchaseAssetDetails {
  const PurchaseAssetDetails({
    required this.assetId,
    this.cadastralReference,
    this.bedrooms,
    this.bathrooms,
    this.surfaceM2,
    this.plotM2,
    this.floor,
    this.yearBuilt,
    this.yearRenovated,
    this.terraceM2,
    this.hasPool,
    this.parkingSpots,
    this.storageRoom,
    this.orientation,
    this.views,
    this.floorPlanUrl,
    this.galleryMedia = const [],
    this.useLightOverlay = true,
  });

  final String assetId;
  final String? cadastralReference;
  final int? bedrooms;
  final int? bathrooms;
  final double? surfaceM2;
  final double? plotM2;
  final String? floor;
  final int? yearBuilt;
  final int? yearRenovated;
  final double? terraceM2;
  final bool? hasPool;
  final int? parkingSpots;
  final bool? storageRoom;
  final String? orientation;
  final String? views;
  final String? floorPlanUrl;
  final List<MediaItem> galleryMedia;
  final bool useLightOverlay;

  /// Physical description of the asset (shown on ACTIVO tab).
  List<AssetInfoEntry> get assetInfo {
    String m2(double v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} m²';
    return [
      if (surfaceM2 != null)
        AssetInfoEntry(label: 'Superficie', value: m2(surfaceM2!)),
      if (plotM2 != null) AssetInfoEntry(label: 'Parcela', value: m2(plotM2!)),
      if (bedrooms != null)
        AssetInfoEntry(label: 'Habitaciones', value: '$bedrooms'),
      if (bathrooms != null)
        AssetInfoEntry(label: 'Baños', value: '$bathrooms'),
      if (floor != null) AssetInfoEntry(label: 'Planta', value: floor!),
      if (orientation != null)
        AssetInfoEntry(label: 'Orientación', value: orientation!),
      if (views != null) AssetInfoEntry(label: 'Vistas', value: views!),
      if (terraceM2 != null)
        AssetInfoEntry(label: 'Terraza', value: m2(terraceM2!)),
      if (hasPool == true) const AssetInfoEntry(label: 'Piscina', value: 'Sí'),
      if (parkingSpots != null)
        AssetInfoEntry(
            label: 'Garaje',
            value: parkingSpots == 1 ? '1 plaza' : '$parkingSpots plazas'),
      if (storageRoom == true)
        const AssetInfoEntry(label: 'Trastero', value: 'Incluido'),
      if (yearBuilt != null)
        AssetInfoEntry(label: 'Año construcción', value: '$yearBuilt'),
      if (yearRenovated != null)
        AssetInfoEntry(label: 'Año renovación', value: '$yearRenovated'),
      if (cadastralReference != null)
        AssetInfoEntry(
            label: 'Ref. catastral',
            value: cadastralReference!,
            copyable: true),
    ];
  }

  static List<MediaItem> _parseMedia(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => MediaItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  factory PurchaseAssetDetails.fromJson(Map<String, dynamic> json) {
    return PurchaseAssetDetails(
      assetId: json['asset_id'] as String,
      cadastralReference: json['asset_cadastral_reference'] as String?,
      bedrooms: json['asset_bedrooms'] as int?,
      bathrooms: json['asset_bathrooms'] as int?,
      surfaceM2: (json['asset_surface_m2'] as num?)?.toDouble(),
      plotM2: (json['asset_plot_m2'] as num?)?.toDouble(),
      floor: json['asset_floor'] as String?,
      yearBuilt: json['asset_year_built'] as int?,
      yearRenovated: json['asset_year_renovated'] as int?,
      terraceM2: (json['asset_terrace_m2'] as num?)?.toDouble(),
      hasPool: json['asset_has_pool'] as bool?,
      parkingSpots: json['asset_parking_spots'] as int?,
      storageRoom: json['asset_storage_room'] as bool?,
      orientation: json['asset_orientation'] as String?,
      views: json['asset_views'] as String?,
      floorPlanUrl: json['asset_floor_plan_url'] as String?,
      galleryMedia: _parseMedia(json['asset_gallery_media']),
      useLightOverlay: json['asset_use_light_overlay'] as bool? ?? true,
    );
  }
}
