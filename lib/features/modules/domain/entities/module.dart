class Module {
  const Module({
    required this.id,
    required this.title,
    required this.order,
    required this.lessonsCount,
    this.isOpened = true,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final int order;
  final int lessonsCount;
  final bool isOpened;
  final bool isCompleted;
}
