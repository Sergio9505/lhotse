enum NotificationType { document, news, phase, financial, delay }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.projectName,
    required this.brandName,
    required this.investmentId,
    required this.date,
    this.isRead = false,
    this.targetTab,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String projectName;
  final String brandName;
  final String investmentId;
  final DateTime date;
  final bool isRead;
  final String? targetTab; // 'proyecto', 'financiero', 'documentos'

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        projectName: projectName,
        brandName: brandName,
        investmentId: investmentId,
        date: date,
        isRead: isRead ?? this.isRead,
        targetTab: targetTab,
      );
}
