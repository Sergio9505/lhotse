import '../../../core/domain/asset_info.dart';
import 'coinvestment_contract_data.dart';
import 'purchase_contract_data.dart';

/// Thin adapter for CompletedDetailScreen.
/// Maps from either PurchaseContractData or CoinvestmentContractData.
class CompletedContractData {
  const CompletedContractData({
    required this.id,
    required this.modelType,
    this.assetId,
    this.projectId,
    required this.projectName,
    required this.brandName,
    this.imageUrl,
    required this.amount,
    this.totalReturn,
    this.actualDuration,
    this.actualRoi,
    this.actualTir,
    this.assetInfo,
    this.galleryImages = const [],
  });

  final String id;
  /// 'purchase' or 'coinvestment' — used for documents query.
  final String modelType;
  /// Set for purchase contracts so the screen can lazy-load asset gallery
  /// via purchaseAssetDetailProvider.
  final String? assetId;
  /// Set for coinvestment contracts so the screen can lazy-load project
  /// renders/asset info via coinvestmentProjectDetailProvider.
  final String? projectId;
  final String projectName;
  final String brandName;
  final String? imageUrl;
  final double amount;
  final double? totalReturn;
  final int? actualDuration;
  final double? actualRoi;
  final double? actualTir;
  final AssetInfo? assetInfo;
  final List<String> galleryImages;

  factory CompletedContractData.fromPurchase(
    PurchaseContractData c, {
    required String brandName,
  }) =>
      CompletedContractData(
        id: c.id,
        modelType: 'purchase',
        assetId: c.assetId,
        projectName: c.assetName ?? '',
        brandName: brandName,
        imageUrl: c.assetImageUrl,
        amount: c.purchaseValue,
        totalReturn: c.totalReturn,
        actualDuration: c.actualDuration,
        actualRoi: c.actualRoi,
      );

  factory CompletedContractData.fromCoinvestment(
    CoinvestmentContractData c, {
    required String brandName,
  }) =>
      CompletedContractData(
        id: c.id,
        modelType: 'coinvestment',
        projectId: c.projectId,
        projectName: c.projectName,
        brandName: brandName,
        imageUrl: c.projectImageUrl,
        amount: c.amount,
        totalReturn: c.totalReturn,
        actualDuration: c.actualDuration,
        actualRoi: c.actualRoi,
        actualTir: c.actualTir,
      );
}
