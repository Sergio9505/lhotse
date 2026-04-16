import 'package:intl/intl.dart';

import '../widgets/lhotse_documents_section.dart';

class DocumentData {
  const DocumentData({
    required this.id,
    required this.modelType,
    required this.modelId,
    required this.name,
    this.date,
    this.category,
    this.fileUrl,
    this.mimeType,
  });

  final String id;
  final String modelType;
  final String modelId;
  final String name;
  final DateTime? date;
  final String? category; // key from document_categories table
  final String? fileUrl;
  final String? mimeType;

  /// Converts to the UI model. Caller provides iconName from document_categories.
  LhotseDocument toLhotseDocument({String iconName = 'fileText'}) =>
      LhotseDocument(
        name: name,
        date: date != null
            ? DateFormat('d MMM. yyyy', 'es_ES').format(date!).toUpperCase()
            : '—',
        categoryKey: category ?? '',
        iconName: iconName,
      );

  factory DocumentData.fromJson(Map<String, dynamic> json) => DocumentData(
        id: json['id'] as String,
        modelType: json['model_type'] as String,
        modelId: json['model_id'] as String,
        name: json['name'] as String,
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String)
            : null,
        category: json['category'] as String?,
        fileUrl: json['file_url'] as String?,
        mimeType: json['mime_type'] as String?,
      );
}
