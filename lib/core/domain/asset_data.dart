/// Lightweight asset row used by the search screen. Full asset detail lives
/// in `PurchaseAssetDetails` / `CoinvestmentProjectDetails` (per-domain lazy
/// views). This model only carries the fields needed for text matching in
/// `/buscar` + rendering a compact result row.
class AssetData {
  const AssetData({
    required this.id,
    this.address,
    this.city,
    this.country,
    this.cadastralReference,
    this.thumbnailImage,
  });

  final String id;
  final String? address;
  final String? city;
  final String? country;
  final String? cadastralReference;
  final String? thumbnailImage;

  String get location {
    final parts = [city, country].whereType<String>().toList();
    return parts.join(', ');
  }

  factory AssetData.fromJson(Map<String, dynamic> json) => AssetData(
        id: json['id'] as String,
        address: json['address'] as String?,
        city: json['city'] as String?,
        country: json['country'] as String?,
        cadastralReference: json['cadastral_reference'] as String?,
        thumbnailImage: json['thumbnail_image'] as String?,
      );
}
