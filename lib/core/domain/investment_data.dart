import 'asset_info.dart';
import 'profit_scenario.dart';
import 'project_phase.dart';

class InvestmentData {
  const InvestmentData({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.brandName,
    required this.amount,
    required this.returnRate,
    required this.durationMonths,
    this.startDate,
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
    this.paymentFrequency,
    this.isCapitalGuaranteed = false,
    this.isDelayed = false,
    this.isCompleted = false,
    this.actualRoi,
    this.netProfit,
    this.totalReturn,
    this.projectedRoi,
    this.completionDate,
    this.actualDuration,
    this.actualTir,
    this.profitScenarios,
    this.phases,
    this.currentPhaseIndex,
    this.renderImages,
    this.progressImages,
    this.videoThumbnailUrl,
    this.videoUrl,
    this.floorPlanUrl,
    this.assetInfo,
    this.economicAnalysis,
  });

  final String id;
  final String projectId;
  final String projectName;
  final String brandName;
  final double amount; // participación
  final double returnRate; // rentabilidad estimada (%)
  final int durationMonths;
  final DateTime? startDate;
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
  final String? paymentFrequency; // e.g. "Trimestral", "Mensual"
  final bool isCapitalGuaranteed;
  final bool isDelayed;
  final bool isCompleted;

  // Completed investment results
  final double? actualRoi;
  final double? netProfit;
  final double? totalReturn;
  final double? projectedRoi;
  final DateTime? completionDate;
  final int? actualDuration; // months
  final double? actualTir;

  // Coinversion detail — profitability, timeline, gallery
  final List<ProfitScenario>? profitScenarios;
  final List<ProjectPhase>? phases;
  final int? currentPhaseIndex;
  final List<String>? renderImages;
  final List<String>? progressImages;
  final String? videoThumbnailUrl;
  final String? videoUrl;
  final String? floorPlanUrl;
  final AssetInfo? assetInfo;
  final List<AssetInfoEntry>? economicAnalysis;
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
