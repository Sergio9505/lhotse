class InvestmentData {
  const InvestmentData({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.brandName,
    required this.amount,
    required this.returnRate,
    required this.durationMonths,
    this.expectedEndDate,
    this.constructionPhase,
    this.purchaseValue,
    this.cashPayment,
    this.mortgage,
    this.mortgageConditions,
    this.monthlyPayment,
    this.mortgageEndDate,
    this.rentalIncome,
    this.revaluation,
    this.unitName,
    this.isCompleted = false,
  });

  final String id;
  final String projectId;
  final String projectName;
  final String brandName;
  final double amount; // participación
  final double returnRate; // rentabilidad estimada (%)
  final int durationMonths;
  final DateTime? expectedEndDate;
  final String? constructionPhase; // "Fase 1", "Fase 2", etc.

  // Operation details (real estate)
  final double? purchaseValue;
  final double? cashPayment;
  final double? mortgage;
  final String? mortgageConditions; // e.g. "RF - 3%"
  final double? monthlyPayment;
  final DateTime? mortgageEndDate;
  final double? rentalIncome;
  final double? revaluation; // revalorización %

  final String? unitName; // e.g. "Piso 1"
  final bool isCompleted;
}

class BrandInvestmentSummary {
  const BrandInvestmentSummary({
    required this.brandName,
    required this.totalAmount,
    required this.averageReturn,
    required this.investments,
  });

  final String brandName;
  final double totalAmount;
  final double averageReturn;
  final List<InvestmentData> investments;
}
