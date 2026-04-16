class PurchaseContractData {
  const PurchaseContractData({
    required this.id,
    required this.userId,
    required this.brandId,
    required this.brandName,
    this.brandLogoAsset,
    required this.purchaseValue,
    this.cashPayment,
    this.purchaseDate,
    // Completion
    this.actualRoi,
    this.totalReturn,
    this.soldDate,
    this.actualDuration,
    // Asset — physical characteristics
    this.assetSurfaceM2,
    this.assetBedrooms,
    this.assetBathrooms,
    this.assetFloor,
    this.assetYearBuilt,
    this.assetYearRenovated,
    this.assetTerraceM2,
    this.assetParkingSpots,
    this.assetStorageRoom,
    this.assetOrientation,
    this.assetViews,
    this.assetPlotM2,
    this.assetHasPool,
    this.assetFloorPlanUrl,
    this.assetGalleryImages = const [],
    this.assetCurrentValue,
    this.assetRevaluationPct,
    // Mortgage
    this.mortgagePrincipal,
    this.mortgageMonthlyPayment,
    this.mortgageEndDate,
    this.mortgageConditions,
    // Rental
    this.monthlyRent,
    this.rentalYieldPct,
    // Asset identity
    this.assetName,
    this.assetLocation,
    this.assetImageUrl,
    this.assetCadastralReference,
  });

  final String id;
  final String userId;
  final String brandId;
  final String brandName;
  final String? brandLogoAsset;
  final double purchaseValue;
  final double? cashPayment;
  final DateTime? purchaseDate;
  final double? actualRoi;
  final double? totalReturn;
  final DateTime? soldDate;
  final int? actualDuration;

  bool get isSold => soldDate != null;

  // Asset — physical characteristics
  final double? assetSurfaceM2;
  final int? assetBedrooms;
  final int? assetBathrooms;
  final String? assetFloor;
  final int? assetYearBuilt;
  final int? assetYearRenovated;
  final double? assetTerraceM2;
  final int? assetParkingSpots;
  final bool? assetStorageRoom;
  final String? assetOrientation;
  final String? assetViews;
  final double? assetPlotM2;
  final bool? assetHasPool;
  final String? assetFloorPlanUrl;
  final List<String> assetGalleryImages;
  final double? assetCurrentValue;
  final double? assetRevaluationPct;

  // Mortgage
  final double? mortgagePrincipal;
  final double? mortgageMonthlyPayment;
  final DateTime? mortgageEndDate;
  final String? mortgageConditions;

  // Rental
  final double? monthlyRent;
  final double? rentalYieldPct;

  // Asset identity
  final String? assetName;
  final String? assetLocation;
  final String? assetImageUrl;
  final String? assetCadastralReference;

  bool get hasFinancing => mortgagePrincipal != null;
  bool get hasActiveRental => monthlyRent != null;

  factory PurchaseContractData.fromJson(Map<String, dynamic> json) {
    final galleryRaw = json['asset_gallery_images'] as List<dynamic>?;

    return PurchaseContractData(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      brandId: json['brand_id'] as String,
      brandName: json['brand_name'] as String? ?? '',
      brandLogoAsset: json['brand_logo_asset'] as String?,
      purchaseValue: (json['purchase_value'] as num).toDouble(),
      cashPayment: (json['cash_payment'] as num?)?.toDouble(),
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'] as String)
          : null,
      actualRoi: (json['actual_roi'] as num?)?.toDouble(),
      totalReturn: (json['total_return'] as num?)?.toDouble(),
      soldDate: json['sold_date'] != null
          ? DateTime.parse(json['sold_date'] as String)
          : null,
      actualDuration: json['actual_duration'] as int?,
      assetSurfaceM2: (json['asset_surface_m2'] as num?)?.toDouble(),
      assetBedrooms: json['asset_bedrooms'] as int?,
      assetBathrooms: json['asset_bathrooms'] as int?,
      assetFloor: json['asset_floor'] as String?,
      assetYearBuilt: json['asset_year_built'] as int?,
      assetYearRenovated: json['asset_year_renovated'] as int?,
      assetTerraceM2: (json['asset_terrace_m2'] as num?)?.toDouble(),
      assetParkingSpots: json['asset_parking_spots'] as int?,
      assetStorageRoom: json['asset_storage_room'] as bool?,
      assetOrientation: json['asset_orientation'] as String?,
      assetViews: json['asset_views'] as String?,
      assetPlotM2: (json['asset_plot_m2'] as num?)?.toDouble(),
      assetHasPool: json['asset_has_pool'] as bool?,
      assetFloorPlanUrl: json['asset_floor_plan_url'] as String?,
      assetGalleryImages: galleryRaw?.cast<String>() ?? [],
      assetCurrentValue: (json['asset_current_value'] as num?)?.toDouble(),
      assetRevaluationPct: (json['asset_revaluation_pct'] as num?)?.toDouble(),
      mortgagePrincipal: (json['mortgage_principal'] as num?)?.toDouble(),
      mortgageMonthlyPayment:
          (json['mortgage_monthly_payment'] as num?)?.toDouble(),
      mortgageEndDate: json['mortgage_end_date'] != null
          ? DateTime.parse(json['mortgage_end_date'] as String)
          : null,
      mortgageConditions: json['mortgage_conditions'] as String?,
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble(),
      rentalYieldPct: (json['rental_yield_pct'] as num?)?.toDouble(),
      assetName: json['asset_name'] as String?,
      assetLocation: json['asset_location'] as String?,
      assetImageUrl: json['asset_thumbnail_image'] as String?,
      assetCadastralReference: json['asset_cadastral_reference'] as String?,
    );
  }
}
