class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.order,
    required this.description,
    required this.videoSource,
  });

  final String id;
  final String title;
  final int order;
  final String description;
  final String videoSource;
}
