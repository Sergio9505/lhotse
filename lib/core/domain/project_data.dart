enum ProjectStatus { inDevelopment, closed }

extension ProjectStatusX on ProjectStatus {
  static ProjectStatus fromString(String value) => switch (value) {
        'in_development' => ProjectStatus.inDevelopment,
        'closed' => ProjectStatus.closed,
        _ => ProjectStatus.inDevelopment,
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
    required this.tagline,
    required this.description,
    this.galleryImages = const [],
    this.isVip = false,
    this.status = ProjectStatus.inDevelopment,
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

  String get location => '$city, $country';

  final String tagline;
  final String description;
  final List<String> galleryImages;
  final bool isVip;
  final ProjectStatus status;

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
      tagline: row['tagline'] as String? ?? '',
      description: row['description'] as String? ?? '',
      galleryImages: galleryRaw?.cast<String>() ?? [],
      isVip: row['is_vip'] as bool? ?? false,
      status: ProjectStatusX.fromString(row['status'] as String? ?? ''),
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
    );
  }

  /// Maps a row from the `get_opportunities` RPC.
  factory ProjectData.fromOpportunityRow(Map<String, dynamic> row) {
    return ProjectData(
      id: row['id'] as String,
      name: row['name'] as String,
      brand: row['brand_name'] as String? ?? '',
      brandLogoAsset: row['logo_asset'] as String?,
      brandId: row['brand_id'] as String?,
      architect: '',
      city: (row['location'] as String? ?? '').split(',').first.trim(),
      country: (row['location'] as String? ?? '').contains(',')
          ? (row['location'] as String).split(',').last.trim()
          : '',
      imageUrl: row['image_url'] as String,
      tagline: '',
      description: '',
      isVip: row['is_vip'] as bool? ?? false,
      status: ProjectStatusX.fromString(row['status'] as String? ?? ''),
    );
  }
}
