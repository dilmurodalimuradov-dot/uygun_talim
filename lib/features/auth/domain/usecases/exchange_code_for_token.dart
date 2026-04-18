import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/auth_token.dart';
import '../repositories/auth_repository.dart';

class ExchangeCodeForToken implements UseCase<AuthToken, String> {
  ExchangeCodeForToken(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthToken>> call(String code) async {
    final tokenResult = await _repository.exchangeCodeForToken(code);

    // Success emasligi tekshiriladi — early return.
    if (tokenResult is ResultFailure<AuthToken>) {
      return tokenResult;
    }
    final token = (tokenResult as Success<AuthToken>).data;

    // Tokenni saqlaymiz.
    final saveResult = await _repository.saveToken(token);
    if (saveResult is ResultFailure<void>) {
      return ResultFailure<AuthToken>(saveResult.failure);
    }

    return Success(token);
  }
}
