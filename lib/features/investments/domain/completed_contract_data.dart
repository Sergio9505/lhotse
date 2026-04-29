import 'coinvestment_contract_data.dart';
import 'purchase_contract_data.dart';
import '../../../core/domain/media_item.dart';

/// Thin adapter for CompletedDetailScreen.
/// Maps from either PurchaseContractData or CoinvestmentContractData.
/// Physical asset info + gallery are loaded lazily in the screen via
/// purchaseAssetDetailProvider / coinvestmentProjectDetailProvider — not
/// carried on this model.
class CompletedContractData {
  const CompletedContractData({
    required this.id,
    required this.modelType,
    this.assetId,
    this.projectId,
    required this.projectName,
    required this.brandName,
    this.location,
    this.imageUrl,
    required this.amount,
    this.totalReturn,
    this.actualDuration,
    this.actualRoi,
    this.actualTir,
    this.galleryMedia = const [],
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
  /// City / location of the underlying asset or project. Mapped from
  /// `assetLocation` (purchase) or `projectLocation` (coinvestment).
  /// May arrive as `City, ES` from upstream — call sites should pipe
  /// through `stripIsoSuffix` before display.
  final String? location;
  final String? imageUrl;
  final double amount;
  final double? totalReturn;
  final int? actualDuration;
  final double? actualRoi;
  final double? actualTir;
  final List<MediaItem> galleryMedia;

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
        location: c.assetLocation,
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
        location: c.projectLocation.isEmpty ? null : c.projectLocation,
        imageUrl: c.projectImageUrl,
        amount: c.amount,
        totalReturn: c.totalReturn,
        actualDuration: c.actualDuration,
        actualRoi: c.actualRoi,
        actualTir: c.actualTir,
      );
}
