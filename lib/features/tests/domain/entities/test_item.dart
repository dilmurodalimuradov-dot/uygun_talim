class TestItem {
  const TestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.questionsCount,
    this.lessonId,
    this.moduleId,
  });

  final String id;
  final String title;
  final String description;
  final int duration;
  final int questionsCount;
  final String? lessonId;
  final String? moduleId;
}
