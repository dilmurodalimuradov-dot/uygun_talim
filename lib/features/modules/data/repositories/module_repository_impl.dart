import '../../../../core/error/exceptions.dart' as app_exc;
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/module.dart';
import '../../domain/repositories/module_repository.dart';
import '../datasources/module_remote_datasource.dart';

class ModuleRepositoryImpl implements ModuleRepository {
  ModuleRepositoryImpl(this._remote);
  final ModuleRemoteDataSource _remote;

  @override
  Future<Result<List<Module>>> getModules({required String courseId}) async {
    try {
      final list = await _remote.fetchModules(courseId);
      return Success(list.whereType<Module>().toList());
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
