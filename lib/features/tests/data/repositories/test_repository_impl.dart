import '../../../../core/error/exceptions.dart' as app_exc;
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/test_item.dart';
import '../../domain/repositories/test_repository.dart';
import '../datasources/test_remote_datasource.dart';

class TestRepositoryImpl implements TestRepository {
  TestRepositoryImpl(this._remote);
  final TestRemoteDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
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
  Future<Result<List<TestItem>>> getTests() =>
      _guard(() => _remote.fetchTests().then((v) => v.whereType<TestItem>().toList()));

  @override
  Future<Result<Map<String, dynamic>>> getTestDetail(String id) =>
      _guard(() => _remote.fetchTestDetail(id));

  @override
  Future<Result<Map<String, dynamic>>> submitTest(
    String id,
    Map<String, dynamic> payload,
  ) =>
      _guard(() => _remote.submitTest(id, payload));
}
