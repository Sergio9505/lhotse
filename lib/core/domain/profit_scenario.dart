class ProfitScenario {
  const ProfitScenario({
    required this.label,
    required this.roiProject,
    required this.roiInvestor,
    required this.tirAnnualized,
    required this.durationMonths,
    required this.estimatedSalePrice,
    required this.netProfit,
  });

  final String label; // "P90", "P50", "P10"
  final double roiProject; // %
  final double roiInvestor; // %
  final double tirAnnualized; // %
  final int durationMonths;
  final double estimatedSalePrice;
  final double netProfit;

  factory ProfitScenario.fromJson(Map<String, dynamic> json) => ProfitScenario(
        label: json['label'] as String,
        roiProject: (json['roi_project'] as num).toDouble(),
        roiInvestor: (json['roi_investor'] as num).toDouble(),
        tirAnnualized: (json['tir_annualized'] as num).toDouble(),
        durationMonths: json['duration_months'] as int,
        estimatedSalePrice: (json['estimated_sale_price'] as num).toDouble(),
        netProfit: (json['net_profit'] as num).toDouble(),
      );
}
