import '../../../../core/error/exceptions.dart' as app_exc;
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/certificate.dart';
import '../../domain/repositories/certificate_repository.dart';
import '../datasources/certificate_remote_datasource.dart';

class CertificateRepositoryImpl implements CertificateRepository {
  CertificateRepositoryImpl(this._remote);
  final CertificateRemoteDataSource _remote;

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
  Future<Result<List<Certificate>>> getCertificates() => _guard(
        () => _remote.fetchCertificates().then((v) => v.whereType<Certificate>().toList()),
      );

  @override
  Future<Result<List<Certificate>>> getMyCertificates() => _guard(
        () => _remote.fetchMyCertificates().then((v) => v.whereType<Certificate>().toList()),
      );

  @override
  Future<Result<Map<String, dynamic>>> getCertificateDetail(String id) =>
      _guard(() => _remote.fetchCertificateDetail(id));
}
