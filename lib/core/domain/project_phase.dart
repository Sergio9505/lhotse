class ProjectPhase {
  const ProjectPhase({
    required this.name,
    this.title,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
  });

  final String name; // "Fase 1", "Fase 2", "Fase 3"
  final String? title; // "Lienzo en blanco", "Diseño en marcha"
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;

  factory ProjectPhase.fromJson(Map<String, dynamic> json) => ProjectPhase(
        name: json['name'] as String,
        title: json['title'] as String?,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        isCompleted: json['is_completed'] as bool? ?? false,
      );
}
