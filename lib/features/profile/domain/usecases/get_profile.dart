import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/profile_info.dart';
import '../repositories/profile_repository.dart';

class GetProfile implements UseCase<ProfileInfo, NoParams> {
  GetProfile(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Result<ProfileInfo>> call(NoParams params) => _repository.getProfile();
}
