import '../../../../core/error/exceptions.dart' as app_exc;
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../datasources/lesson_remote_datasource.dart';

class LessonRepositoryImpl implements LessonRepository {
  LessonRepositoryImpl(this._remote);
  final LessonRemoteDataSource _remote;

  @override
  Future<Result<List<Lesson>>> getLessons({required String moduleId}) async {
    try {
      final lessons = await _remote.fetchLessons(moduleId);
      return Success(lessons.whereType<Lesson>().toList());
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
}
