import '../utils/hero_media_parser.dart';
import 'content_block.dart';
import 'media_item.dart';

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

  /// Mixed-case label for inline bylines. preConstruction and construction
  /// collapse — the investor doesn't need to distinguish raising from building.
  String get label => switch (this) {
        ProjectPhase.preConstruction ||
        ProjectPhase.construction =>
          'En desarrollo',
        ProjectPhase.exited => 'Finalizado',
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
    this.imageUrl,
    this.imageUrls = const [],
    this.videoUrl,
    this.virtualTourUrl,
    this.virtualTourThumbnailUrl,
    this.progressTourThumbnailUrl,
    required this.tagline,
    this.content = const [],
    this.galleryMedia = const [],
    this.isVip = false,
    this.isFundraisingOpen = true,
    this.phase = ProjectPhase.preConstruction,
    this.constructionCompletedAt,
    this.builtSurfaceM2,
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
    this.usableSurfaceM2,
    this.hasElevator,
    this.floorPlanUrl,
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
  /// Cover image read by every list-row consumer (feed card, archive,
  /// L1/L2/L3 rows, hero shuttle). Denormalized from `hero_media[0]`
  /// (ADR-71); the admin keeps it in sync on save.
  final String? imageUrl;

  /// Ordered hero gallery (image-only). Drives the PageView in the
  /// `ProjectDetailScreen` hero when `videoUrl == null` and
  /// `imageUrls.length > 1`. Per ADR-62 + ADR-71, `videoUrl` always wins
  /// over this list. Distinct from [galleryMedia] which is the
  /// post-cierre gallery shown in a dedicated scroll section.
  final List<String> imageUrls;

  final String? videoUrl;
  final String? virtualTourUrl;

  /// Optional editable thumbnail for the commercial virtual tour entry
  /// point (`VirtualTourSection`). Falls back to [imageUrl] when null
  /// (preserves historical behaviour for rows with no thumbnail set).
  final String? virtualTourThumbnailUrl;

  /// Optional editable thumbnail for the progress (avance de obra) tour
  /// shown in the L3 coinversion AVANCE tab. Falls back to [imageUrl] when
  /// null.
  final String? progressTourThumbnailUrl;

  String get location => '$city, $country';

  final String tagline;

  /// Editorial body of the project detail. Ordered list of typed blocks
  /// (heading / text / image / gallery / video) rendered by
  /// `ProjectContentRenderer`. Stored in `projects.content` (jsonb).
  /// Replaces the old free-text `description` column (migration
  /// `20260524120000_project_content_blocks.sql`).
  final List<ContentBlock> content;
  final List<MediaItem> galleryMedia;
  final bool isVip;

  /// True while the project accepts new investors. Orthogonal to `phase`:
  /// construction can start while fundraising is still open.
  final bool isFundraisingOpen;

  /// Physical stage of the asset. Orthogonal to `isFundraisingOpen`.
  final ProjectPhase phase;

  /// Optional marker for the "construction done, sale pending" window.
  final DateTime? constructionCompletedAt;

  // Asset physical characteristics
  final double? builtSurfaceM2;
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
  final double? usableSurfaceM2;
  final bool? hasElevator;
  final String? floorPlanUrl;
  final String? assetId;
  final bool useLightOverlay;

  /// Maps a Supabase row from `projects` joined with `brands` and `assets`.
  static List<MediaItem> _parseGalleryMedia(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => MediaItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  static List<ContentBlock> _parseContent(dynamic raw) {
    if (raw is! List) return const [];
    final result = <ContentBlock>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        result.add(ContentBlock.fromJson(Map<String, Object?>.from(item)));
      } catch (_) {
        // Forward-compat: unknown block types or malformed entries are
        // silently skipped so the rest of the body still renders.
      }
    }
    return result;
  }

  factory ProjectData.fromSupabaseRow(Map<String, dynamic> row) {
    final brands = row['brands'] as Map<String, dynamic>?;
    final assets = row['assets'] as Map<String, dynamic>?;
    final imageUrl = row['image_url'] as String?;
    final imageUrls = parseHeroMediaImageUrls(row['hero_media']);

    return ProjectData(
      id: row['id'] as String,
      name: row['name'] as String,
      brand: brands?['name'] as String? ?? '',
      brandLogoAsset: brands?['logo_asset'] as String?,
      brandId: row['brand_id'] as String?,
      architect: row['architect'] as String? ?? '',
      city: assets?['city'] as String? ?? '',
      country: assets?['country'] as String? ?? '',
      imageUrl: imageUrl,
      imageUrls: imageUrls.isNotEmpty
          ? imageUrls
          : (imageUrl != null && imageUrl.isNotEmpty
              ? <String>[imageUrl]
              : const <String>[]),
      videoUrl: row['video_url'] as String?,
      virtualTourUrl: row['virtual_tour_url'] as String?,
      virtualTourThumbnailUrl: row['virtual_tour_thumbnail_url'] as String?,
      progressTourThumbnailUrl: row['progress_tour_thumbnail_url'] as String?,
      tagline: row['tagline'] as String? ?? '',
      content: _parseContent(row['content']),
      galleryMedia: _parseGalleryMedia(row['gallery_media']),
      isVip: row['is_vip'] as bool? ?? false,
      isFundraisingOpen: row['is_fundraising_open'] as bool? ?? true,
      phase: ProjectPhase.fromDb(row['phase'] as String?),
      constructionCompletedAt: row['construction_completed_at'] != null
          ? DateTime.parse(row['construction_completed_at'] as String)
          : null,
      builtSurfaceM2: (assets?['built_surface_m2'] as num?)?.toDouble(),
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
      usableSurfaceM2: (assets?['usable_surface_m2'] as num?)?.toDouble(),
      hasElevator: assets?['has_elevator'] as bool?,
      floorPlanUrl: assets?['floor_plan_url'] as String?,
      assetId: row['asset_id'] as String?,
      useLightOverlay: row['use_light_overlay'] as bool? ?? true,
    );
  }
}
