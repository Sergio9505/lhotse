class DocumentCategoryData {
  const DocumentCategoryData({
    required this.key,
    required this.label,
    required this.iconName,
    required this.sortOrder,
  });

  final String key;
  final String label;
  final String iconName;
  final int sortOrder;

  factory DocumentCategoryData.fromJson(Map<String, dynamic> json) =>
      DocumentCategoryData(
        key: json['key'] as String,
        label: json['label'] as String,
        iconName: json['icon_name'] as String,
        sortOrder: json['sort_order'] as int? ?? 0,
      );
}
