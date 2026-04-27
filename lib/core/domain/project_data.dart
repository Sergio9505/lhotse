/// Physical stage of a coinvestment project asset.
///
/// `projects` table only describes coinvestment (flip model: raise → build → sell),
/// so 3 phases suffice; there is no long-term "operating" state.
enum ProjectPhase {
  preConstruction,
  construction,
  exited;

  static ProjectPhase fromDb(String? value) => switch (value) {
        'construction' => ProjectPhase.construction,
        'exited' => ProjectPhase.exited,
        _ => ProjectPhase.preConstruction,
      };

  /// Uppercase user-facing label used in editorial kickers (card + detail).
  /// preConstruction and construction collapse to a single "EN DESARROLLO"
  /// state — the investor doesn't need to distinguish "raising" from "building"
  /// at catalog level. Only the exit is a separate visual state.
  String get label => switch (this) {
        ProjectPhase.preConstruction ||
        ProjectPhase.construction =>
          'EN DESARROLLO',
        ProjectPhase.exited => 'FINALIZADO',
      };
}

class ProjectData {
  const ProjectData({
    required this.id,
    required this.name,
    required this.brand,
    this.brandLogoAsset,
    this.brandId,
    required this.architect,
    required this.city,
    required this.country,
    required this.imageUrl,
    this.videoUrl,
    required this.tagline,
    required this.description,
    this.galleryImages = const [],
    this.isVip = false,
    this.isFundraisingOpen = true,
    this.phase = ProjectPhase.preConstruction,
    this.constructionCompletedAt,
    this.surfaceM2,
    this.bedrooms,
    this.bathrooms,
    this.floor,
    this.yearBuilt,
    this.yearRenovated,
    this.terraceM2,
    this.parkingSpots,
    this.storageRoom,
    this.orientation,
    this.views,
    this.plotM2,
    this.hasPool,
    this.floorPlanUrl,
    this.brochureUrl,
    this.assetId,
    this.useLightOverlay = true,
  });

  final String id;
  final String name;
  final String brand;
  final String? brandLogoAsset;
  final String? brandId;
  final String architect;
  final String city;
  final String country;
  final String imageUrl;
  final String? videoUrl;

  String get location => '$city, $country';

  final String tagline;
  final String description;
  final List<String> galleryImages;
  final bool isVip;

  /// True while the project accepts new investors. Orthogonal to `phase`:
  /// construction can start while fundraising is still open.
  final bool isFundraisingOpen;

  /// Physical stage of the asset. Orthogonal to `isFundraisingOpen`.
  final ProjectPhase phase;

  /// Optional marker for the "construction done, sale pending" window.
  final DateTime? constructionCompletedAt;

  // Asset physical characteristics
  final double? surfaceM2;
  final int? bedrooms;
  final int? bathrooms;
  final String? floor;
  final int? yearBuilt;
  final int? yearRenovated;
  final double? terraceM2;
  final int? parkingSpots;
  final bool? storageRoom;
  final String? orientation;
  final String? views;
  final double? plotM2;
  final bool? hasPool;
  final String? floorPlanUrl;
  final String? brochureUrl;
  final String? assetId;
  final bool useLightOverlay;

  /// Maps a Supabase row from `projects` joined with `brands` and `assets`.
  factory ProjectData.fromSupabaseRow(Map<String, dynamic> row) {
    final brands = row['brands'] as Map<String, dynamic>?;
    final assets = row['assets'] as Map<String, dynamic>?;
    final galleryRaw = row['gallery_images'] as List<dynamic>?;

    return ProjectData(
      id: row['id'] as String,
      name: row['name'] as String,
      brand: brands?['name'] as String? ?? '',
      brandLogoAsset: brands?['logo_asset'] as String?,
      brandId: row['brand_id'] as String?,
      architect: row['architect'] as String? ?? '',
      city: assets?['city'] as String? ?? '',
      country: assets?['country'] as String? ?? '',
      imageUrl: row['image_url'] as String,
      videoUrl: row['video_url'] as String?,
      tagline: row['tagline'] as String? ?? '',
      description: row['description'] as String? ?? '',
      galleryImages: galleryRaw?.cast<String>() ?? [],
      isVip: row['is_vip'] as bool? ?? false,
      isFundraisingOpen: row['is_fundraising_open'] as bool? ?? true,
      phase: ProjectPhase.fromDb(row['phase'] as String?),
      constructionCompletedAt: row['construction_completed_at'] != null
          ? DateTime.parse(row['construction_completed_at'] as String)
          : null,
      surfaceM2: (assets?['surface_m2'] as num?)?.toDouble(),
      bedrooms: assets?['bedrooms'] as int?,
      bathrooms: assets?['bathrooms'] as int?,
      floor: assets?['floor'] as String?,
      yearBuilt: assets?['year_built'] as int?,
      yearRenovated: assets?['year_renovated'] as int?,
      terraceM2: (assets?['terrace_m2'] as num?)?.toDouble(),
      parkingSpots: assets?['parking_spots'] as int?,
      storageRoom: assets?['storage_room'] as bool?,
      orientation: assets?['orientation'] as String?,
      views: assets?['views'] as String?,
      plotM2: (assets?['plot_m2'] as num?)?.toDouble(),
      hasPool: assets?['has_pool'] as bool?,
      floorPlanUrl: assets?['floor_plan_url'] as String?,
      brochureUrl: row['brochure_url'] as String?,
      assetId: row['asset_id'] as String?,
      useLightOverlay: row['use_light_overlay'] as bool? ?? true,
    );
  }
}
