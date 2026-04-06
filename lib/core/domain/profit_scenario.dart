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
}
