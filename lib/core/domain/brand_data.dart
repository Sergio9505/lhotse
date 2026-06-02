// Brand-level classifier — mirrors the `brands.business_model` DB CHECK
// (coinvestment | direct_purchase | fixed_income | rental). `rental` is a
// brand classification, NOT an investor-facing contract button (see DOMAIN.md).
enum BusinessModel { directPurchase, coinvestment, fixedIncome, rental }

extension BusinessModelLabel on BusinessModel {
  String get displayName => switch (this) {
        BusinessModel.directPurchase => 'Adquisición',
        BusinessModel.coinvestment => 'Coinversión',
        BusinessModel.fixedIncome => 'Renta Fija',
        BusinessModel.rental => 'Alquiler',
      };

  static BusinessModel fromString(String value) => switch (value) {
        'direct_purchase' => BusinessModel.directPurchase,
        'coinvestment' => BusinessModel.coinvestment,
        'fixed_income' => BusinessModel.fixedIncome,
        'rental' => BusinessModel.rental,
        _ => BusinessModel.coinvestment,
      };
}

class BrandData {
  const BrandData({
    required this.id,
    required this.name,
    this.logoAsset,
    this.logoAssetDetail,
    required this.coverImageUrl,
    required this.businessModel,
    this.tagline,
    this.description,
    this.websiteUrl,
  });

  final String id;
  final String name;
  final String? logoAsset;
  final String? logoAssetDetail;
  final String coverImageUrl;
  final BusinessModel businessModel;
  final String? tagline;
  final String? description;
  final String? websiteUrl;

  factory BrandData.fromJson(Map<String, dynamic> json) => BrandData(
        id: json['id'] as String,
        name: json['name'] as String,
        logoAsset: json['logo_asset'] as String?,
        logoAssetDetail: json['logo_asset_detail'] as String?,
        coverImageUrl: json['cover_image_url'] as String? ?? '',
        businessModel: BusinessModelLabel.fromString(
          json['business_model'] as String? ?? '',
        ),
        tagline: json['tagline'] as String?,
        description: json['description'] as String?,
        websiteUrl: json['website_url'] as String?,
      );
}
