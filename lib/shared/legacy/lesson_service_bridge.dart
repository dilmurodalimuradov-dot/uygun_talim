import '../../core/constants/api_constants.dart';
import '../../core/di/service_locator.dart';
import '../../features/lessons/domain/entities/lesson.dart' as domain;

class Lesson {
  Lesson({
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

  factory Lesson.fromDomain(domain.Lesson l) => Lesson(
        id: l.id,
        title: l.title,
        order: l.order,
        description: l.description,
        videoSource: l.videoSource,
      );
}

class LessonService {
  Future<List<Lesson>> fetchLessons(
    String token, {
    required String moduleId,
  }) async {
    final result = await ServiceLocator.getLessons(moduleId);
    return result.when(
      success: (list) => list.map(Lesson.fromDomain).toList(),
      failure: (f) => throw Exception(f.message),
    );
  }

  String get csrfToken => ApiConstants.csrfToken;
}
