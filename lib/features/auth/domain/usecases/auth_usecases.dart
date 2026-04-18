import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatus implements UseCase<bool, NoParams> {
  CheckAuthStatus(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<bool>> call(NoParams params) async {
    final tokenResult = await _repository.getAccessToken();
    return tokenResult.when(
      success: (token) => Success(token != null && token.isNotEmpty),
      failure: (f) => ResultFailure(f),
    );
  }
}

class Logout implements UseCase<void, NoParams> {
  Logout(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.logout();
}
