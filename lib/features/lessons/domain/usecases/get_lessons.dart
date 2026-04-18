import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/lesson.dart';
import '../repositories/lesson_repository.dart';

class GetLessons implements UseCase<List<Lesson>, String> {
  GetLessons(this._repository);
  final LessonRepository _repository;

  @override
  Future<Result<List<Lesson>>> call(String moduleId) =>
      _repository.getLessons(moduleId: moduleId);
}
