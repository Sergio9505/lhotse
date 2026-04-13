enum BusinessModel { compraDirecta, coinversion, rentaFija }

extension BusinessModelLabel on BusinessModel {
  String get displayName => switch (this) {
        BusinessModel.compraDirecta => 'Compra Directa',
        BusinessModel.coinversion => 'Coinversión',
        BusinessModel.rentaFija => 'Renta Fija',
      };
}

class BrandData {
  const BrandData({
    required this.id,
    required this.name,
    this.logoAsset,
    required this.coverImageUrl,
    required this.businessModel,
    this.tagline,
    this.description,
    this.websiteUrl,
  });

  final String id;
  final String name;
  final String? logoAsset;
  final String coverImageUrl;
  final BusinessModel businessModel;

  /// Short editorial one-liner shown prominently in brand detail.
  final String? tagline;

  /// Body description. The business model name ([businessModel.displayName])
  /// is highlighted in bold inside the detail screen via RichText.
  final String? description;

  /// Brand website URL opened by the CTA button.
  final String? websiteUrl;
}
