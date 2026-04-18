import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../repositories/auth_repository.dart';

class GetAuthorizationUrl implements UseCase<String, NoParams> {
  GetAuthorizationUrl(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<String>> call(NoParams params) {
    return _repository.fetchAuthorizationUrl();
  }
}
