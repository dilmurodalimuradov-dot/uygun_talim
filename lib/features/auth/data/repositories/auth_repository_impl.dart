import '../../../../core/error/exceptions.dart' as app_exc;
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/token_local_datasource.dart';

/// Repository — data qatlamining "yuzi".
/// Exception'larni tutib, toza Failure qaytaradi.
/// Shu tufayli presentation qatlami xatolarni bir xil tarzda ko'rsatadi.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenLocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource;

  final AuthRemoteDataSource _remote;
  final TokenLocalDataSource _local;

  @override
  Future<Result<String>> fetchAuthorizationUrl() async {
    try {
      final url = await _remote.fetchAuthorizationUrl();
      return Success(url);
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
  Future<Result<AuthToken>> exchangeCodeForToken(String code) async {
    try {
      final token = await _remote.exchangeCode(code);
      return Success(token);
    } on app_exc.UnauthorizedException catch (e) {
      return ResultFailure(AuthFailure(e.message));
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
  Future<Result<String?>> getAccessToken() async {
    try {
      final token = await _local.getAccessToken();
      return Success(token);
    } on app_exc.CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<String?>> getRefreshToken() async {
    try {
      final token = await _local.getRefreshToken();
      return Success(token);
    } on app_exc.CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveToken(AuthToken token) async {
    try {
      await _local.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );
      return const Success(null);
    } on app_exc.CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _local.clearTokens();
      return const Success(null);
    } on app_exc.CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> isTokenValid() async {
    try {
      final valid = await _local.isTokenValid();
      return Success(valid);
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> refreshAccessToken() async {
    // Hozircha sodda: faqat refresh tokenni tekshiradi.
    // Haqiqiy endpoint chaqirish uchun remote datasource'da method qo'shish kerak.
    return const ResultFailure(
      AuthFailure('Refresh endpoint hali implementatsiya qilinmagan.'),
    );
  }
}
