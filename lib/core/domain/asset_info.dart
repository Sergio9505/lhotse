class AssetInfo {
  const AssetInfo({required this.entries});

  final List<AssetInfoEntry> entries;
}

class AssetInfoEntry {
  const AssetInfoEntry({required this.label, required this.value});

  final String label; // "Superficie"
  final String value; // "308 m²"
}
