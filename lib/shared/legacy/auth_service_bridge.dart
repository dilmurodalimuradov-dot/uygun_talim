import '../../core/di/service_locator.dart';
import '../../core/utils/usecase.dart';
import '../../features/auth/data/models/auth_token_model.dart';

class AuthService {
  Future<String> fetchAuthorizationUrl() async {
    final result = await ServiceLocator.getAuthorizationUrl(const NoParams());
    return result.when(
      success: (url) => url,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<Map<String, dynamic>> exchangeCode(String code) async {
    final result = await ServiceLocator.exchangeCodeForToken(code);
    return result.when(
      success: (token) => {
        'access_token': token.accessToken,
        if (token.refreshToken != null) 'refresh_token': token.refreshToken,
      },
      failure: (f) => throw Exception(f.message),
    );
  }
}
