import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/course.dart';
import '../repositories/course_repository.dart';

class GetCourses implements UseCase<List<Course>, NoParams> {
  GetCourses(this._repository);
  final CourseRepository _repository;

  @override
  Future<Result<List<Course>>> call(NoParams params) =>
      _repository.getCourses();
}

class GetCourseDetail implements UseCase<Course, String> {
  GetCourseDetail(this._repository);
  final CourseRepository _repository;

  @override
  Future<Result<Course>> call(String id) => _repository.getCourseDetail(id);
}

class StartCourse implements UseCase<void, String> {
  StartCourse(this._repository);
  final CourseRepository _repository;

  @override
  Future<Result<void>> call(String id) => _repository.startCourse(id);
}

class GetCourseProgress implements UseCase<Map<String, dynamic>, String> {
  GetCourseProgress(this._repository);
  final CourseRepository _repository;

  @override
  Future<Result<Map<String, dynamic>>> call(String id) =>
      _repository.getCourseProgress(id);
}
