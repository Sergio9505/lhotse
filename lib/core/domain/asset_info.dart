class AssetInfo {
  const AssetInfo({required this.entries});

  final List<AssetInfoEntry> entries;

  static AssetInfo fromJsonList(dynamic json) => AssetInfo(
        entries: (json as List<dynamic>?)
                ?.map((e) => AssetInfoEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class AssetInfoEntry {
  const AssetInfoEntry({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final String label; // "Superficie"
  final String value; // "308 m²"
  final bool copyable;

  factory AssetInfoEntry.fromJson(Map<String, dynamic> json) => AssetInfoEntry(
        label: json['label'] as String,
        value: json['value'] as String,
      );

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}
