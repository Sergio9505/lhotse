import '../../../core/domain/asset_info.dart';
import '../../../core/domain/profit_scenario.dart';
import '../../../core/domain/project_phase.dart';

class CoinvestmentContractData {
  const CoinvestmentContractData({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.brandId,
    required this.brandName,
    this.brandLogoAsset,
    required this.businessModel,
    required this.amount,
    this.isCompleted = false,
    this.isDelayed = false,
    // Coinvestment specifics
    this.estimatedReturnPct,
    this.estimatedDurationMonths,
    this.startDate,
    this.expectedEndDate,
    this.currentPhaseIndex,
    this.constructionPhase,
    // Completion
    this.actualRoi,
    this.netProfit,
    this.totalReturn,
    this.projectedRoi,
    this.completionDate,
    this.actualDuration,
    this.actualTir,
    // Asset (may not exist during construction)
    this.assetId,
    this.assetUnitName,
    this.assetFloorPlanUrl,
    this.assetGalleryImages = const [],
    this.assetCurrentValue,
    this.assetRevaluationPct,
    // Project
    required this.projectName,
    required this.projectLocation,
    required this.projectImageUrl,
    this.projectStatus,
    this.projectGalleryImages = const [],
    this.renderImages = const [],
    this.progressImages = const [],
    this.videoUrl,
    this.videoThumbnailUrl,
    this.economicAnalysis,
    // Loaded separately via providers
    this.profitScenarios = const [],
    this.phases = const [],
  });

  final String id;
  final String userId;
  final String projectId;
  final String brandId;
  final String brandName;
  final String? brandLogoAsset;
  final String businessModel;
  final double amount;
  final bool isCompleted;
  final bool isDelayed;
  final double? estimatedReturnPct;
  final int? estimatedDurationMonths;
  final DateTime? startDate;
  final DateTime? expectedEndDate;
  final int? currentPhaseIndex;
  final String? constructionPhase;
  final double? actualRoi;
  final double? netProfit;
  final double? totalReturn;
  final double? projectedRoi;
  final DateTime? completionDate;
  final int? actualDuration;
  final double? actualTir;
  final String? assetId;
  final String? assetUnitName;
  final String? assetFloorPlanUrl;
  final List<String> assetGalleryImages;
  final double? assetCurrentValue;
  final double? assetRevaluationPct;
  final String projectName;
  final String projectLocation;
  final String projectImageUrl;
  final String? projectStatus;
  final List<String> projectGalleryImages;
  final List<String> renderImages;
  final List<String> progressImages;
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final List<AssetInfoEntry>? economicAnalysis;
  final List<ProfitScenario> profitScenarios;
  final List<ProjectPhase> phases;

  CoinvestmentContractData copyWith({
    List<ProfitScenario>? profitScenarios,
    List<ProjectPhase>? phases,
  }) =>
      CoinvestmentContractData(
        id: id, userId: userId, projectId: projectId, brandId: brandId,
        brandName: brandName, brandLogoAsset: brandLogoAsset, businessModel: businessModel,
        amount: amount, isCompleted: isCompleted, isDelayed: isDelayed,
        estimatedReturnPct: estimatedReturnPct, estimatedDurationMonths: estimatedDurationMonths,
        startDate: startDate, expectedEndDate: expectedEndDate,
        currentPhaseIndex: currentPhaseIndex, constructionPhase: constructionPhase,
        actualRoi: actualRoi, netProfit: netProfit, totalReturn: totalReturn,
        projectedRoi: projectedRoi, completionDate: completionDate,
        actualDuration: actualDuration, actualTir: actualTir,
        assetId: assetId, assetUnitName: assetUnitName, assetFloorPlanUrl: assetFloorPlanUrl,
        assetGalleryImages: assetGalleryImages, assetCurrentValue: assetCurrentValue,
        assetRevaluationPct: assetRevaluationPct,
        projectName: projectName, projectLocation: projectLocation,
        projectImageUrl: projectImageUrl, projectStatus: projectStatus,
        projectGalleryImages: projectGalleryImages, renderImages: renderImages,
        progressImages: progressImages, videoUrl: videoUrl, videoThumbnailUrl: videoThumbnailUrl,
        economicAnalysis: economicAnalysis,
        profitScenarios: profitScenarios ?? this.profitScenarios,
        phases: phases ?? this.phases,
      );

  factory CoinvestmentContractData.fromJson(Map<String, dynamic> json) {
    List<String> _strings(dynamic raw) =>
        (raw as List<dynamic>?)?.cast<String>() ?? [];

    List<AssetInfoEntry>? _entries(dynamic raw) => raw == null
        ? null
        : (raw as List<dynamic>)
            .map((e) => AssetInfoEntry.fromJson(e as Map<String, dynamic>))
            .toList();

    return CoinvestmentContractData(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String,
      brandId: json['brand_id'] as String,
      brandName: json['brand_name'] as String? ?? '',
      brandLogoAsset: json['brand_logo_asset'] as String?,
      businessModel: json['business_model'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      isCompleted: json['is_completed'] as bool? ?? false,
      isDelayed: json['is_delayed'] as bool? ?? false,
      estimatedReturnPct: (json['estimated_return_pct'] as num?)?.toDouble(),
      estimatedDurationMonths: json['estimated_duration_months'] as int?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      expectedEndDate: json['expected_end_date'] != null
          ? DateTime.parse(json['expected_end_date'] as String)
          : null,
      currentPhaseIndex: json['current_phase_index'] as int?,
      constructionPhase: json['construction_phase'] as String?,
      actualRoi: (json['actual_roi'] as num?)?.toDouble(),
      netProfit: (json['net_profit'] as num?)?.toDouble(),
      totalReturn: (json['total_return'] as num?)?.toDouble(),
      projectedRoi: (json['projected_roi'] as num?)?.toDouble(),
      completionDate: json['completion_date'] != null
          ? DateTime.parse(json['completion_date'] as String)
          : null,
      actualDuration: json['actual_duration'] as int?,
      actualTir: (json['actual_tir'] as num?)?.toDouble(),
      assetId: json['asset_id'] as String?,
      assetUnitName: json['asset_unit_name'] as String?,
      assetFloorPlanUrl: json['asset_floor_plan_url'] as String?,
      assetGalleryImages: _strings(json['asset_gallery_images']),
      assetCurrentValue: (json['asset_current_value'] as num?)?.toDouble(),
      assetRevaluationPct: (json['asset_revaluation_pct'] as num?)?.toDouble(),
      projectName: json['project_name'] as String? ?? '',
      projectLocation: json['project_location'] as String? ?? '',
      projectImageUrl: json['project_image_url'] as String? ?? '',
      projectStatus: json['project_status'] as String?,
      projectGalleryImages: _strings(json['project_gallery_images']),
      renderImages: _strings(json['render_images']),
      progressImages: _strings(json['progress_images']),
      videoUrl: json['video_url'] as String?,
      videoThumbnailUrl: json['video_thumbnail_url'] as String?,
      economicAnalysis: _entries(json['economic_analysis']),
    );
  }
}
