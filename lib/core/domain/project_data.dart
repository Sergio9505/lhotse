import 'asset_info.dart';

enum ProjectStatus { inDevelopment, signatures, closed }

extension ProjectStatusX on ProjectStatus {
  static ProjectStatus fromString(String value) => switch (value) {
        'in_development' => ProjectStatus.inDevelopment,
        'signatures' => ProjectStatus.signatures,
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
    required this.location,
    this.address,
    required this.imageUrl,
    required this.tagline,
    required this.description,
    this.galleryImages = const [],
    this.isVip = false,
    this.status = ProjectStatus.inDevelopment,
    this.bedrooms,
    this.bathrooms,
    this.details,
    this.floorPlanUrl,
    this.assetId,
  });

  final String id;
  final String name;
  final String brand;
  final String? brandLogoAsset;
  final String? brandId;
  final String architect;
  final String location;
  final String? address;
  final String imageUrl;
  final String tagline;
  final String description;
  final List<String> galleryImages;
  final bool isVip;
  final ProjectStatus status;
  final int? bedrooms;
  final int? bathrooms;
  final AssetInfo? details;
  final String? floorPlanUrl;
  final String? assetId;

  /// Maps a Supabase row from `projects` joined with `brands(name, logo_asset)`.
  factory ProjectData.fromSupabaseRow(Map<String, dynamic> row) {
    final brands = row['brands'] as Map<String, dynamic>?;
    final galleryRaw = row['gallery_images'] as List<dynamic>?;

    return ProjectData(
      id: row['id'] as String,
      name: row['name'] as String,
      brand: brands?['name'] as String? ?? '',
      brandLogoAsset: brands?['logo_asset'] as String?,
      brandId: row['brand_id'] as String?,
      architect: row['architect'] as String? ?? '',
      location: row['location'] as String,
      address: row['address'] as String?,
      imageUrl: row['image_url'] as String,
      tagline: row['tagline'] as String? ?? '',
      description: row['description'] as String? ?? '',
      galleryImages: galleryRaw?.cast<String>() ?? [],
      isVip: row['is_vip'] as bool? ?? false,
      status: ProjectStatusX.fromString(row['status'] as String? ?? ''),
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
      location: row['location'] as String,
      imageUrl: row['image_url'] as String,
      tagline: '',
      description: '',
      isVip: row['is_vip'] as bool? ?? false,
      status: ProjectStatusX.fromString(row['status'] as String? ?? ''),
    );
  }
}
