/// Strips the trailing ISO 3166-1 alpha-2 country code suffix (e.g.
/// `, ES`, `, FR`) from a location string.
///
/// Convention from `ProjectShowcaseCard.city`: location strings shown to
/// the investor display the city only, not the compound `City, COUNTRY`
/// form that often arrives from upstream data sources. Used in:
/// - `_PurchaseRow` (L2 active Compra Directa card)
/// - `direct_purchase_detail_screen` (L3 active Compra Directa subtítulo)
/// - `completed_detail_screen` (L3 finalizadas — both CD and coinv)
/// - `coinversion_detail_screen` (L3 active coinv subtítulo)
///
/// Returns the input unchanged if it doesn't end with the pattern.
String stripIsoSuffix(String location) =>
    location.replaceFirst(RegExp(r',\s*[A-Z]{2}$'), '');
