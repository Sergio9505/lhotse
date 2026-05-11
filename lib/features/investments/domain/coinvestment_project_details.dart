import 'package:intl/intl.dart';

import '../../../core/domain/asset_info.dart';
import '../../../core/domain/media_item.dart';

/// Per-project data for the coinvestion detail screen tabs (ACTIVO, AVANCE,
/// FINANZAS). Loaded lazily via `coinvestmentProjectDetailProvider(projectId)`.
///
/// Shared across all investor contracts in the same project — the DB view
/// returns one row per project, not per contract.
class CoinvestmentProjectDetails {
  const CoinvestmentProjectDetails({
    required this.projectId,
    this.renderMedia = const [],
    this.progressTourUrl,
    // Asset
    this.assetBuiltSurfaceM2,
    this.assetUsableSurfaceM2,
    this.assetBedrooms,
    this.assetBathrooms,
    this.assetFloor,
    this.assetOrientation,
    this.assetViews,
    this.assetTerraceM2,
    this.assetHasElevator,
    this.assetParkingSpots,
    this.assetStorageRoom,
    this.assetYearBuilt,
    this.assetYearRenovated,
    this.assetCadastralReference,
    this.assetFloorPlanUrl,
    // Economics
    this.targetCapital,
    this.purchasePrice,
    this.builtSqm,
    this.agencyCommission,
    this.itpAmount,
    this.purchaseExpensesAmount,
    this.renovationCost,
    this.furnitureCost,
    this.otherCosts,
    this.totalCost,
    this.useLightOverlay = true,
    this.videoUrl,
    this.virtualTourUrl,
  });

  final String projectId;
  final List<MediaItem> renderMedia;
  final String? progressTourUrl;
  final double? assetBuiltSurfaceM2;
  final double? assetUsableSurfaceM2;
  final int? assetBedrooms;
  final int? assetBathrooms;
  final String? assetFloor;
  final String? assetOrientation;
  final String? assetViews;
  final double? assetTerraceM2;
  final bool? assetHasElevator;
  final int? assetParkingSpots;
  final bool? assetStorageRoom;
  final int? assetYearBuilt;
  final int? assetYearRenovated;
  final String? assetCadastralReference;
  final String? assetFloorPlanUrl;
  final double? targetCapital;
  final double? purchasePrice;
  final double? builtSqm;
  final double? agencyCommission;
  final double? itpAmount;
  final double? purchaseExpensesAmount;
  final double? renovationCost;
  final double? furnitureCost;
  final double? otherCosts;
  final double? totalCost;
  final bool useLightOverlay;
  final String? videoUrl;
  final String? virtualTourUrl;

  /// Physical description of the asset (shown on ACTIVO tab).
  List<AssetInfoEntry> get assetInfo {
    String m2(double v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} m²';
    return [
      if (assetBuiltSurfaceM2 != null)
        AssetInfoEntry(
            label: 'Superficie construida', value: m2(assetBuiltSurfaceM2!)),
      if (assetTerraceM2 != null)
        AssetInfoEntry(label: 'Terraza', value: m2(assetTerraceM2!)),
      if (assetUsableSurfaceM2 != null)
        AssetInfoEntry(
            label: 'Superficie útil', value: m2(assetUsableSurfaceM2!)),
      if (assetBedrooms != null)
        AssetInfoEntry(label: 'Habitaciones', value: '$assetBedrooms'),
      if (assetBathrooms != null)
        AssetInfoEntry(label: 'Baños', value: '$assetBathrooms'),
      if (assetFloor != null)
        AssetInfoEntry(label: 'Planta', value: assetFloor!),
      if (assetOrientation != null)
        AssetInfoEntry(label: 'Orientación', value: assetOrientation!),
      if (assetViews != null)
        AssetInfoEntry(label: 'Vistas', value: assetViews!),
      if (assetHasElevator == true)
        const AssetInfoEntry(label: 'Ascensor', value: 'Sí'),
      if (assetParkingSpots != null)
        AssetInfoEntry(
            label: 'Garaje',
            value: assetParkingSpots == 1
                ? '1 plaza'
                : '$assetParkingSpots plazas'),
      if (assetStorageRoom == true)
        const AssetInfoEntry(label: 'Trastero', value: 'Incluido'),
      if (assetYearBuilt != null)
        AssetInfoEntry(label: 'Año construcción', value: '$assetYearBuilt'),
      if (assetYearRenovated != null)
        AssetInfoEntry(label: 'Año renovación', value: '$assetYearRenovated'),
      if (assetCadastralReference != null)
        AssetInfoEntry(
            label: 'Ref. catastral',
            value: assetCadastralReference!,
            copyable: true),
    ];
  }

  /// Economic breakdown of the project (shown on FINANZAS tab).
  List<AssetInfoEntry> get economicAnalysis {
    final f = NumberFormat.decimalPattern('es_ES');
    String eur(double? v) => '${f.format(v!.round())} €';
    String sqm(double? v) => '${f.format(v!.round())} m²';
    return [
      if (purchasePrice != null)
        AssetInfoEntry(label: 'Precio compra', value: eur(purchasePrice)),
      if (builtSqm != null)
        AssetInfoEntry(label: 'm² construidos', value: sqm(builtSqm)),
      if (purchasePrice != null && builtSqm != null && builtSqm! > 0)
        AssetInfoEntry(
            label: '€/m² construido',
            value: eur(purchasePrice! / builtSqm!)),
      if (agencyCommission != null)
        AssetInfoEntry(label: 'Comisión agencia', value: eur(agencyCommission)),
      if (itpAmount != null)
        AssetInfoEntry(label: 'ITP (2%)', value: eur(itpAmount)),
      if (purchaseExpensesAmount != null)
        AssetInfoEntry(
            label: 'Gastos compra (1%)', value: eur(purchaseExpensesAmount)),
      if (renovationCost != null)
        AssetInfoEntry(label: 'Reforma piso', value: eur(renovationCost)),
      if (furnitureCost != null)
        AssetInfoEntry(label: 'Mobiliario', value: eur(furnitureCost)),
      if (otherCosts != null)
        AssetInfoEntry(label: 'Otros', value: eur(otherCosts)),
      if (totalCost != null && totalCost! > 0)
        AssetInfoEntry(label: 'Gastos totales', value: eur(totalCost)),
    ];
  }

  static List<MediaItem> _parseMedia(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => MediaItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  factory CoinvestmentProjectDetails.fromJson(Map<String, dynamic> json) {
    return CoinvestmentProjectDetails(
      projectId: json['project_id'] as String,
      renderMedia: _parseMedia(json['render_media']),
      progressTourUrl: json['progress_tour_url'] as String?,
      assetBuiltSurfaceM2:
          (json['asset_built_surface_m2'] as num?)?.toDouble(),
      assetUsableSurfaceM2:
          (json['asset_usable_surface_m2'] as num?)?.toDouble(),
      assetBedrooms: json['asset_bedrooms'] as int?,
      assetBathrooms: json['asset_bathrooms'] as int?,
      assetFloor: json['asset_floor'] as String?,
      assetOrientation: json['asset_orientation'] as String?,
      assetViews: json['asset_views'] as String?,
      assetTerraceM2: (json['asset_terrace_m2'] as num?)?.toDouble(),
      assetHasElevator: json['asset_has_elevator'] as bool?,
      assetParkingSpots: json['asset_parking_spots'] as int?,
      assetStorageRoom: json['asset_storage_room'] as bool?,
      assetYearBuilt: json['asset_year_built'] as int?,
      assetYearRenovated: json['asset_year_renovated'] as int?,
      assetCadastralReference: json['asset_cadastral_reference'] as String?,
      assetFloorPlanUrl: json['asset_floor_plan_url'] as String?,
      targetCapital: (json['target_capital'] as num?)?.toDouble(),
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      builtSqm: (json['built_sqm'] as num?)?.toDouble(),
      agencyCommission: (json['agency_commission'] as num?)?.toDouble(),
      itpAmount: (json['itp_amount'] as num?)?.toDouble(),
      purchaseExpensesAmount:
          (json['purchase_expenses_amount'] as num?)?.toDouble(),
      renovationCost: (json['renovation_cost'] as num?)?.toDouble(),
      furnitureCost: (json['furniture_cost'] as num?)?.toDouble(),
      otherCosts: (json['other_costs'] as num?)?.toDouble(),
      totalCost: (json['total_cost'] as num?)?.toDouble(),
      useLightOverlay: json['project_use_light_overlay'] as bool? ?? true,
      videoUrl: json['video_url'] as String?,
      virtualTourUrl: json['virtual_tour_url'] as String?,
    );
  }
}
