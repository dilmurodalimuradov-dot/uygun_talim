import '../../../../core/error/exceptions.dart' as app_exc;
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_datasource.dart';

class CourseRepositoryImpl implements CourseRepository {
  CourseRepositoryImpl(this._remote);
  final CourseRemoteDataSource _remote;

  /// Har bir repository metodida takrorlanadigan try/catch
  /// mantiqini bitta joyga olib chiqish.
  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      final data = await action();
      return Success(data);
    } on app_exc.UnauthorizedException catch (e) {
      return ResultFailure(UnauthorizedFailure(e.message));
    } on app_exc.ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on app_exc.TimeoutException catch (e) {
      return ResultFailure(TimeoutFailure(e.message));
    } on app_exc.NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Course>>> getCourses() =>
      _guard(() async {
        final list = await _remote.fetchCourses();
        return list.whereType<Course>().toList();
      });

  @override
  Future<Result<Course>> getCourseDetail(String id) =>
      _guard(() => _remote.fetchCourseDetail(id));

  @override
  Future<Result<void>> startCourse(String id) =>
      _guard(() => _remote.startCourse(id));

  @override
  Future<Result<Map<String, dynamic>>> getCourseProgress(String id) =>
      _guard(() => _remote.fetchCourseProgress(id));
}
