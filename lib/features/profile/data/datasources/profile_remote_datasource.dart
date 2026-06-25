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
    // DIQQAT: ApiConstants.profileEndpoints ro'yxati allaqachon to'liq
    // prefiks bilan yozilgan ('/api-v1/account/me/', '/api/account/me/').
    // Shuning uchun bu yerda baseUrlOverride sifatida ApiConstants.baseUrlV1
    // ('$baseHost/api-v1') emas, balki sof ApiConstants.baseHost berilishi
    // kerak — aks holda yakuniy manzil
    // "$baseHost/api-v1/api-v1/account/me/" bo'lib, prefiks ikki marta
    // qo'shilib ketadi va server 404 qaytarib, "Profilni olishda xatolik"
    // ko'rsatiladi.
    final response = await _apiClient.getFirstAvailable(
      ApiConstants.profileEndpoints,
      baseUrlOverride: ApiConstants.baseHost,
    );
    final data = JsonParser.decodeMap(response);
    return ProfileInfoModel.fromJson(data);
  }
}
