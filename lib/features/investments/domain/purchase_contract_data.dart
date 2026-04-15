import '../../../core/domain/asset_info.dart';

class PurchaseContractData {
  const PurchaseContractData({
    required this.id,
    required this.userId,
    required this.brandId,
    required this.assetId,
    required this.brandName,
    this.brandLogoAsset,
    required this.businessModel,
    required this.purchaseValue,
    this.cashPayment,
    this.purchaseDate,
    this.isCompleted = false,
    this.isDelayed = false,
    // Completion
    this.actualRoi,
    this.netProfit,
    this.totalReturn,
    this.projectedRoi,
    this.completionDate,
    this.actualDuration,
    this.actualTir,
    // Asset
    this.assetUnitName,
    this.assetBedrooms,
    this.assetBathrooms,
    this.assetSurfaceM2,
    this.assetFloorPlanUrl,
    this.assetGalleryImages = const [],
    this.assetCurrentValue,
    this.assetRevaluationPct,
    this.assetInfo,
    // Mortgage
    this.mortgageType,
    this.mortgagePrincipal,
    this.mortgageRate,
    this.mortgageMonthlyPayment,
    this.mortgageEndDate,
    this.mortgageConditions,
    // Rental
    this.rentalContractId,
    this.monthlyRent,
    this.annualIncreasePct,
    this.rentalBrandId,
    this.rentalYieldPct,
    // Project context
    this.projectId,
    this.projectName,
    this.projectLocation,
    this.projectImageUrl,
    this.projectStatus,
  });

  final String id;
  final String userId;
  final String brandId;
  final String assetId;
  final String brandName;
  final String? brandLogoAsset;
  final String businessModel;
  final double purchaseValue;
  final double? cashPayment;
  final DateTime? purchaseDate;
  final bool isCompleted;
  final bool isDelayed;
  final double? actualRoi;
  final double? netProfit;
  final double? totalReturn;
  final double? projectedRoi;
  final DateTime? completionDate;
  final int? actualDuration;
  final double? actualTir;
  final String? assetUnitName;
  final int? assetBedrooms;
  final int? assetBathrooms;
  final double? assetSurfaceM2;
  final String? assetFloorPlanUrl;
  final List<String> assetGalleryImages;
  final double? assetCurrentValue;
  final double? assetRevaluationPct;
  final AssetInfo? assetInfo;
  final String? mortgageType;
  final double? mortgagePrincipal;
  final double? mortgageRate;
  final double? mortgageMonthlyPayment;
  final DateTime? mortgageEndDate;
  final String? mortgageConditions;
  final String? rentalContractId;
  final double? monthlyRent;
  final double? annualIncreasePct;
  final String? rentalBrandId;
  final double? rentalYieldPct;
  final String? projectId;
  final String? projectName;
  final String? projectLocation;
  final String? projectImageUrl;
  final String? projectStatus;

  bool get hasFinancing => mortgagePrincipal != null;
  bool get hasActiveRental => monthlyRent != null;

  factory PurchaseContractData.fromJson(Map<String, dynamic> json) {
    final galleryRaw = json['asset_gallery_images'] as List<dynamic>?;
    final assetInfoRaw = json['asset_info'];

    return PurchaseContractData(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      brandId: json['brand_id'] as String,
      assetId: json['asset_id'] as String,
      brandName: json['brand_name'] as String? ?? '',
      brandLogoAsset: json['brand_logo_asset'] as String?,
      businessModel: json['business_model'] as String? ?? '',
      purchaseValue: (json['purchase_value'] as num).toDouble(),
      cashPayment: (json['cash_payment'] as num?)?.toDouble(),
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      isDelayed: json['is_delayed'] as bool? ?? false,
      actualRoi: (json['actual_roi'] as num?)?.toDouble(),
      netProfit: (json['net_profit'] as num?)?.toDouble(),
      totalReturn: (json['total_return'] as num?)?.toDouble(),
      projectedRoi: (json['projected_roi'] as num?)?.toDouble(),
      completionDate: json['completion_date'] != null
          ? DateTime.parse(json['completion_date'] as String)
          : null,
      actualDuration: json['actual_duration'] as int?,
      actualTir: (json['actual_tir'] as num?)?.toDouble(),
      assetUnitName: json['asset_unit_name'] as String?,
      assetBedrooms: json['asset_bedrooms'] as int?,
      assetBathrooms: json['asset_bathrooms'] as int?,
      assetSurfaceM2: (json['asset_surface_m2'] as num?)?.toDouble(),
      assetFloorPlanUrl: json['asset_floor_plan_url'] as String?,
      assetGalleryImages: galleryRaw?.cast<String>() ?? [],
      assetCurrentValue: (json['asset_current_value'] as num?)?.toDouble(),
      assetRevaluationPct: (json['asset_revaluation_pct'] as num?)?.toDouble(),
      assetInfo: assetInfoRaw != null
          ? AssetInfo.fromJsonList(assetInfoRaw)
          : null,
      mortgageType: json['mortgage_type'] as String?,
      mortgagePrincipal: (json['mortgage_principal'] as num?)?.toDouble(),
      mortgageRate: (json['mortgage_rate'] as num?)?.toDouble(),
      mortgageMonthlyPayment:
          (json['mortgage_monthly_payment'] as num?)?.toDouble(),
      mortgageEndDate: json['mortgage_end_date'] != null
          ? DateTime.parse(json['mortgage_end_date'] as String)
          : null,
      mortgageConditions: json['mortgage_conditions'] as String?,
      rentalContractId: json['rental_contract_id'] as String?,
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble(),
      annualIncreasePct: (json['annual_increase_pct'] as num?)?.toDouble(),
      rentalBrandId: json['rental_brand_id'] as String?,
      rentalYieldPct: (json['rental_yield_pct'] as num?)?.toDouble(),
      projectId: json['project_id'] as String?,
      projectName: json['project_name'] as String?,
      projectLocation: json['project_location'] as String?,
      projectImageUrl: json['project_image_url'] as String?,
      projectStatus: json['project_status'] as String?,
    );
  }
}
