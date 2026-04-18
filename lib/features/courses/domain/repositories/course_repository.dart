import '../../../../core/utils/result.dart';
import '../entities/course.dart';

abstract class CourseRepository {
  Future<Result<List<Course>>> getCourses();
  Future<Result<Course>> getCourseDetail(String id);
  Future<Result<void>> startCourse(String id);
  Future<Result<Map<String, dynamic>>> getCourseProgress(String id);
}
