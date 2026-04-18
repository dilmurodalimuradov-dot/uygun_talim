import '../../../../core/utils/result.dart';
import '../entities/lesson.dart';

abstract class LessonRepository {
  Future<Result<List<Lesson>>> getLessons({required String moduleId});
}
