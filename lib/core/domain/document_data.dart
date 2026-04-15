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
  final String? category; // DB: 'legal'|'financial'|'construction'|'tax'|'contract'|'certificate'|'report'
  final String? fileUrl;
  final String? mimeType;

  DocCategory? get docCategory => _categoryFromDb(category);

  /// Converts to the UI model used by LhotseDocumentsSection / LhotseDocRow.
  LhotseDocument toLhotseDocument() => LhotseDocument(
        name: name,
        date: date != null
            ? DateFormat('d MMM. yyyy', 'es_ES').format(date!).toUpperCase()
            : '—',
        category: docCategory ?? DocCategory.legal,
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

  static DocCategory? _categoryFromDb(String? value) => switch (value) {
        'legal' => DocCategory.legal,
        'financial' => DocCategory.financiero,
        'construction' => DocCategory.obra,
        'tax' => DocCategory.fiscal,
        'contract' => DocCategory.contrato,
        'certificate' => DocCategory.certificado,
        'report' => DocCategory.informe,
        _ => null,
      };
}
