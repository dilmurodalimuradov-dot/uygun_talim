import '../../../../core/error/exceptions.dart' as app_exc;
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/profile_info.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);
  final ProfileRemoteDataSource _remote;

  @override
  Future<Result<ProfileInfo>> getProfile() async {
    try {
      final profile = await _remote.fetchProfile();
      return Success(profile);
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
