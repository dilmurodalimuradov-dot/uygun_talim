class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.order,
    required this.description,
    required this.videoSource,
    this.testId,
    this.hasTest = false,
    this.isFullyWatched = false,
    this.isCompleted = false,
    this.testPassed = false,
  });

  final String id;
  final String title;
  final int order;
  final String description;
  final String videoSource;
  final String? testId;
  final bool hasTest;
  final bool isFullyWatched;
  final bool isCompleted;
  final bool testPassed;
}