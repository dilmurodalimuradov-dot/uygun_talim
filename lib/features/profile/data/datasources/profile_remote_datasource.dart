import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_parser.dart';
import '../models/profile_info_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileInfoModel> fetchProfile();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<ProfileInfoModel> fetchProfile() async {
    final response = await _apiClient.getFirstAvailable(
      ApiConstants.profileEndpoints,
      baseUrlOverride: ApiConstants.baseUrlV1,
    );
    final data = JsonParser.decodeMap(response);
    return ProfileInfoModel.fromJson(data);
  }
}
