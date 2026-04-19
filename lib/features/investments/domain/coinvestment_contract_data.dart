import '../../../core/domain/contract_status.dart';
import '../../../core/domain/profit_scenario.dart';
import '../../../core/domain/project_phase.dart';

/// Per-contract data used by list screens + detail hero.
/// Heavy project/asset/economics fields live in `CoinvestmentProjectDetails`
/// (lazy-loaded by `coinvestmentProjectDetailProvider(projectId)`).
class CoinvestmentContractData {
  const CoinvestmentContractData({
    required this.id,
    required this.projectId,
    required this.brandId,
    required this.amount,
    required this.status,
    this.isCompleted = false,
    this.startDate,
    this.estimatedReturnPct,
    this.estimatedDurationMonths,
    this.actualRoi,
    this.totalReturn,
    this.actualDuration,
    this.actualTir,
    required this.projectName,
    required this.projectLocation,
    required this.projectImageUrl,
    // Loaded separately via providers
    this.profitScenarios = const [],
    this.phases = const [],
  });

  final String id;
  final String projectId;
  final String brandId;
  final double amount;
  final ContractStatus status;

  /// Derived in `user_coinvestments` view as `completion_date IS NOT NULL`.
  final bool isCompleted;

  final DateTime? startDate;
  final double? estimatedReturnPct;
  final int? estimatedDurationMonths;
  final double? actualRoi;
  final double? totalReturn;
  final int? actualDuration;
  final double? actualTir;
  final String projectName;
  final String projectLocation;
  final String projectImageUrl;
  final List<ProfitScenario> profitScenarios;
  final List<ProjectPhase> phases;

  CoinvestmentContractData copyWith({
    List<ProfitScenario>? profitScenarios,
    List<ProjectPhase>? phases,
  }) =>
      CoinvestmentContractData(
        id: id,
        projectId: projectId,
        brandId: brandId,
        amount: amount,
        status: status,
        isCompleted: isCompleted,
        startDate: startDate,
        estimatedReturnPct: estimatedReturnPct,
        estimatedDurationMonths: estimatedDurationMonths,
        actualRoi: actualRoi,
        totalReturn: totalReturn,
        actualDuration: actualDuration,
        actualTir: actualTir,
        projectName: projectName,
        projectLocation: projectLocation,
        projectImageUrl: projectImageUrl,
        profitScenarios: profitScenarios ?? this.profitScenarios,
        phases: phases ?? this.phases,
      );

  factory CoinvestmentContractData.fromJson(Map<String, dynamic> json) {
    return CoinvestmentContractData(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      brandId: json['brand_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: ContractStatusX.fromString(json['status'] as String?),
      isCompleted: json['is_completed'] as bool? ?? false,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      estimatedReturnPct: (json['estimated_return_pct'] as num?)?.toDouble(),
      estimatedDurationMonths: json['estimated_duration_months'] as int?,
      actualRoi: (json['actual_roi'] as num?)?.toDouble(),
      totalReturn: (json['total_return'] as num?)?.toDouble(),
      actualDuration: json['actual_duration'] as int?,
      actualTir: (json['actual_tir'] as num?)?.toDouble(),
      projectName: json['project_name'] as String? ?? '',
      projectLocation: json['project_location'] as String? ?? '',
      projectImageUrl: json['project_image_url'] as String? ?? '',
    );
  }
}
