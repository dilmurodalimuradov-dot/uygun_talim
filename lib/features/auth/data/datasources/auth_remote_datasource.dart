import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart' as app_exc;
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_parser.dart';
import '../models/auth_token_model.dart';

abstract class AuthRemoteDataSource {
  Future<String> fetchAuthorizationUrl();
  Future<AuthTokenModel> exchangeCode(String code);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<String> fetchAuthorizationUrl() async {
    final response = await _apiClient.getFirstAvailable(
      ApiConstants.authorizationEndpoints,
      requiresAuth: false,
      baseUrlOverride: ApiConstants.baseUrlV1,
    );

    final body = JsonParser.decodeMap(response);

    // `authorization_url` field'i to'g'ridan-to'g'ri yoki data ichida bo'lishi mumkin.
    final directUrl = body['authorization_url'] as String?;
    if (directUrl != null && directUrl.isNotEmpty) return directUrl;

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final url = data['authorization_url'] as String?;
      if (url != null && url.isNotEmpty) return url;
    }

    throw app_exc.ServerException('Authorization URL topilmadi.');
  }

  @override
  Future<AuthTokenModel> exchangeCode(String code) async {
    final response = await _apiClient.getFirstAvailable(
      ApiConstants.callbackEndpoints,
      queryParameters: {'code': code},
      requiresAuth: false,
      baseUrlOverride: ApiConstants.baseUrlV1,
    );

    final body = JsonParser.decodeMap(response);
    try {
      return AuthTokenModel.fromJson(body);
    } catch (e) {
      throw app_exc.ServerException(e.toString());
    }
  }
}
