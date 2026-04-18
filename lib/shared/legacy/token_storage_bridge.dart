import '../../core/di/service_locator.dart';


class TokenStorageService {
  Future<String?> readAccessToken() =>
      ServiceLocator.tokenLocal.getAccessToken();

  Future<String?> readRefreshToken() =>
      ServiceLocator.tokenLocal.getRefreshToken();

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) =>
      ServiceLocator.tokenLocal.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

  Future<void> saveAccessToken(String token) =>
      ServiceLocator.tokenLocal.saveAccessToken(token);

  Future<void> clearTokens() => ServiceLocator.tokenLocal.clearTokens();

  Future<bool> isValidToken() => ServiceLocator.tokenLocal.isTokenValid();
}
