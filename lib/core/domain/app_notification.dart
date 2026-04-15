enum NotificationType { document, news, phase, financial, delay }

extension NotificationTypeX on NotificationType {
  static NotificationType fromString(String value) => switch (value) {
        'document' => NotificationType.document,
        'news' => NotificationType.news,
        'phase' => NotificationType.phase,
        'financial' => NotificationType.financial,
        'delay' => NotificationType.delay,
        _ => NotificationType.news,
      };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.projectName,
    this.brandName,
    this.modelType,
    this.modelId,
    required this.date,
    this.isRead = false,
    this.targetTab,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String? projectName;
  final String? brandName;
  final String? modelType;
  final String? modelId;
  final DateTime date;
  final bool isRead;
  final String? targetTab;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: NotificationTypeX.fromString(json['type'] as String? ?? ''),
        title: json['title'] as String,
        projectName: json['project_name'] as String?,
        brandName: json['brand_name'] as String?,
        modelType: json['model_type'] as String?,
        modelId: json['model_id'] as String?,
        date: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
        targetTab: json['target_tab'] as String?,
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        projectName: projectName,
        brandName: brandName,
        modelType: modelType,
        modelId: modelId,
        date: date,
        isRead: isRead ?? this.isRead,
        targetTab: targetTab,
      );
}
