/// Aggregated brand-level investment summary (from `brand_investment_summaries` view).
class BrandInvestmentSummaryData {
  const BrandInvestmentSummaryData({
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

  factory BrandInvestmentSummaryData.fromJson(Map<String, dynamic> json) =>
      BrandInvestmentSummaryData(
        brandId: json['brand_id'] as String,
        brandName: json['brand_name'] as String,
        brandLogoAsset: json['logo_asset'] as String?,
        businessModel: json['business_model'] as String? ?? '',
        totalAmount: (json['total_amount'] as num).toDouble(),
        avgReturnPct: (json['avg_return_pct'] as num?)?.toDouble(),
        activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
      );
}

/// User-level portfolio totals (from `portfolio_summaries` view).
class PortfolioSummary {
  const PortfolioSummary({
    required this.totalInvested,
    this.avgReturnPct,
    required this.activeCount,
  });

  final double totalInvested;
  final double? avgReturnPct;
  final int activeCount;

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) =>
      PortfolioSummary(
        totalInvested: (json['total_invested'] as num?)?.toDouble() ?? 0,
        avgReturnPct: (json['avg_return_pct'] as num?)?.toDouble(),
        activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
      );
}
