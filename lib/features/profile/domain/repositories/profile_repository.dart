import '../../../../core/utils/result.dart';
import '../entities/profile_info.dart';

abstract class ProfileRepository {
  Future<Result<ProfileInfo>> getProfile();
}
