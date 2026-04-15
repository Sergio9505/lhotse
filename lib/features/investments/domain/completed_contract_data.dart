import '../../../core/domain/asset_info.dart';
import 'coinvestment_contract_data.dart';
import 'purchase_contract_data.dart';

/// Thin adapter for CompletedDetailScreen.
/// Maps from either PurchaseContractData or CoinvestmentContractData.
class CompletedContractData {
  const CompletedContractData({
    required this.id,
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

  factory CompletedContractData.fromPurchase(PurchaseContractData c) =>
      CompletedContractData(
        id: c.id,
        projectName: c.projectName ?? c.assetUnitName ?? '',
        brandName: c.brandName,
        imageUrl: c.projectImageUrl,
        amount: c.purchaseValue,
        totalReturn: c.totalReturn,
        actualDuration: c.actualDuration,
        actualRoi: c.actualRoi,
        actualTir: c.actualTir,
        assetInfo: c.assetInfo,
        galleryImages: c.assetGalleryImages,
      );

  factory CompletedContractData.fromCoinvestment(CoinvestmentContractData c) =>
      CompletedContractData(
        id: c.id,
        projectName: c.projectName,
        brandName: c.brandName,
        imageUrl: c.projectImageUrl,
        amount: c.amount,
        totalReturn: c.totalReturn,
        actualDuration: c.actualDuration,
        actualRoi: c.actualRoi,
        actualTir: c.actualTir,
        galleryImages: c.renderImages,
      );
}
