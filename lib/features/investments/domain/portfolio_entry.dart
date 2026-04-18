/// One row of the user's portfolio — investment totals per brand.
/// Read from the `user_portfolio` Supabase view.
class PortfolioEntry {
  const PortfolioEntry({
    required this.brandId,
    required this.brandName,
    this.brandLogoAsset,
    required this.businessModel,
    required this.totalAmount,
    this.avgReturnPct,
    required this.activeCount,
  });

  final String brandId;
  final String brandName;
  final String? brandLogoAsset;
  final String businessModel;
  final double totalAmount;
  final double? avgReturnPct;
  final int activeCount;

  factory PortfolioEntry.fromJson(Map<String, dynamic> json) => PortfolioEntry(
        brandId: json['brand_id'] as String,
        brandName: json['brand_name'] as String,
        brandLogoAsset: json['logo_asset'] as String?,
        businessModel: json['business_model'] as String? ?? '',
        totalAmount: (json['total_amount'] as num).toDouble(),
        avgReturnPct: (json['avg_return_pct'] as num?)?.toDouble(),
        activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
      );
}
