enum BusinessModel { directPurchase, coinvestment, fixedIncome }

extension BusinessModelLabel on BusinessModel {
  String get displayName => switch (this) {
        BusinessModel.directPurchase => 'Adquisición',
        BusinessModel.coinvestment => 'Coinversión',
        BusinessModel.fixedIncome => 'Renta Fija',
      };

  static BusinessModel fromString(String value) => switch (value) {
        'direct_purchase' => BusinessModel.directPurchase,
        'coinvestment' => BusinessModel.coinvestment,
        'fixed_income' => BusinessModel.fixedIncome,
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
