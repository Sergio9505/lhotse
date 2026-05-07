import '../../../core/domain/contract_status.dart';

/// Per-contract data for list screens + L3 hero.
///
/// Tab content is split into dedicated lazy views:
///   - Asset physical characteristics → `PurchaseAssetDetails`
///     (tab ACTIVO, loaded by `purchaseAssetDetailProvider(assetId)`).
///   - Mortgage breakdown → `PurchaseMortgageDetails`
///     (tab FINANCIACIÓN, loaded by `purchaseMortgageDetailProvider(contractId)`).
///
/// `hasFinancing` is kept here as a lightweight boolean so the L3 can decide
/// whether to render the FINANCIACIÓN tab without fetching the details.
class PurchaseContractData {
  const PurchaseContractData({
    required this.id,
    required this.brandId,
    required this.assetId,
    required this.purchaseValue,
    required this.status,
    required this.isCompleted,
    this.cashPayment,
    this.purchaseDate,
    this.hasFinancing = false,
    // Completion
    this.actualRoi,
    this.totalReturn,
    this.soldDate,
    this.actualDuration,
    // Asset identity (shown in list + hero)
    this.assetName,
    this.assetLocation,
    this.assetImageUrl,
    this.videoUrl,
    this.assetRevaluationPct,
    // Rental (hero metric)
    this.monthlyRent,
    this.rentalYieldPct,
  });

  final String id;
  final String brandId;
  final String assetId;
  final double purchaseValue;
  final ContractStatus status;

  /// Derived in `user_direct_purchases` view as `sold_date IS NOT NULL`.
  final bool isCompleted;

  final double? cashPayment;
  final DateTime? purchaseDate;
  final bool hasFinancing;
  final double? actualRoi;
  final double? totalReturn;
  final DateTime? soldDate;
  final int? actualDuration;

  final String? assetName;
  final String? assetLocation;
  final String? assetImageUrl;
  final String? videoUrl;
  final double? assetRevaluationPct;

  final double? monthlyRent;
  final double? rentalYieldPct;

  bool get hasActiveRental => monthlyRent != null;

  factory PurchaseContractData.fromJson(Map<String, dynamic> json) {
    return PurchaseContractData(
      id: json['id'] as String,
      brandId: json['brand_id'] as String,
      assetId: json['asset_id'] as String,
      purchaseValue: (json['purchase_value'] as num).toDouble(),
      status: ContractStatusX.fromString(json['status'] as String?),
      isCompleted: json['is_completed'] as bool? ?? false,
      cashPayment: (json['cash_payment'] as num?)?.toDouble(),
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'] as String)
          : null,
      hasFinancing: json['has_financing'] as bool? ?? false,
      actualRoi: (json['actual_roi'] as num?)?.toDouble(),
      totalReturn: (json['total_return'] as num?)?.toDouble(),
      soldDate: json['sold_date'] != null
          ? DateTime.parse(json['sold_date'] as String)
          : null,
      actualDuration: json['actual_duration'] as int?,
      assetName: json['asset_name'] as String?,
      assetLocation: json['asset_location'] as String?,
      assetImageUrl: json['asset_thumbnail_image'] as String?,
      videoUrl: json['video_url'] as String?,
      assetRevaluationPct: (json['asset_revaluation_pct'] as num?)?.toDouble(),
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble(),
      rentalYieldPct: (json['rental_yield_pct'] as num?)?.toDouble(),
    );
  }
}
