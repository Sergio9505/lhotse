import 'package:intl/intl.dart';

import '../widgets/lhotse_documents_section.dart';

class DocumentData {
  const DocumentData({
    required this.id,
    required this.scope,
    required this.name,
    this.date,
    this.categoryId,
    this.fileUrl,
    this.projectId,
    this.assetId,
    this.userId,
    this.relatedProjectId,
    this.relatedAssetId,
    this.relatedCoinvestmentId,
    this.relatedPurchaseId,
    this.relatedRentalId,
    this.relatedFixedIncomeId,
  });

  final String id;
  final String scope; // 'project' | 'asset' | 'investor'
  final String name;
  final DateTime? date;
  final String? categoryId;
  final String? fileUrl;
  // Primary FK (set by scope)
  final String? projectId;
  final String? assetId;
  final String? userId;
  // Investor context (optional, scope='investor' only)
  final String? relatedProjectId;
  final String? relatedAssetId;
  final String? relatedCoinvestmentId;
  final String? relatedPurchaseId;
  final String? relatedRentalId;
  final String? relatedFixedIncomeId;

  /// Converts to the UI model. Caller provides iconName from document_categories.
  LhotseDocument toLhotseDocument({String iconName = 'fileText'}) =>
      LhotseDocument(
        id: id,
        name: name,
        date: date != null
            ? DateFormat('d MMM. yyyy', 'es_ES').format(date!).toUpperCase()
            : '—',
        categoryId: categoryId ?? '',
        iconName: iconName,
        fileUrl: fileUrl,
      );

  factory DocumentData.fromJson(Map<String, dynamic> json) => DocumentData(
        id: json['id'] as String,
        scope: json['scope'] as String? ?? 'investor',
        name: json['name'] as String,
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String)
            : null,
        categoryId: json['category_id'] as String?,
        fileUrl: json['file_url'] as String?,
        projectId: json['project_id'] as String?,
        assetId: json['asset_id'] as String?,
        userId: json['user_id'] as String?,
        relatedProjectId: json['related_project_id'] as String?,
        relatedAssetId: json['related_asset_id'] as String?,
        relatedCoinvestmentId: json['related_coinvestment_id'] as String?,
        relatedPurchaseId: json['related_purchase_id'] as String?,
        relatedRentalId: json['related_rental_id'] as String?,
        relatedFixedIncomeId: json['related_fixed_income_id'] as String?,
      );
}
