enum BusinessModel { compraDirecta, coinversion, ciclo, rentaFija }

class BrandData {
  const BrandData({
    required this.id,
    required this.name,
    this.logoAsset,
    required this.coverImageUrl,
    required this.businessModel,
  });

  final String id;
  final String name;
  final String? logoAsset;
  final String coverImageUrl;
  final BusinessModel businessModel;
}
