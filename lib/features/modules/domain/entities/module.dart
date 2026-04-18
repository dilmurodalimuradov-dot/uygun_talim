class Module {
  const Module({
    required this.id,
    required this.title,
    required this.order,
    required this.lessonsCount,
  });

  final String id;
  final String title;
  final int order;
  final int lessonsCount;
}
