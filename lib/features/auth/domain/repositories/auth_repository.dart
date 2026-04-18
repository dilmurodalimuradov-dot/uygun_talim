import '../../../../core/utils/result.dart';
import '../entities/auth_token.dart';

/// Domain qatlamidagi shartnoma.
/// Repository presentationga qanday ishlatilishini aytadi,
/// lekin implementatsiyani data qatlamga qoldiradi.
abstract class AuthRepository {
  /// OAuth2 authorization URL olish (brauzerda ochish uchun).
  Future<Result<String>> fetchAuthorizationUrl();

  /// Code'ni token'ga almashtirish.
  Future<Result<AuthToken>> exchangeCodeForToken(String code);

  /// Saqlangan access tokenni olish.
  Future<Result<String?>> getAccessToken();

  /// Refresh tokenni olish.
  Future<Result<String?>> getRefreshToken();

  /// Tokenni saqlash.
  Future<Result<void>> saveToken(AuthToken token);

  /// Chiqish (barcha tokenlarni o'chirish).
  Future<Result<void>> logout();

  /// Token yaroqlimi (expired emas, formati to'g'ri)?
  Future<Result<bool>> isTokenValid();

  /// Refresh token orqali yangi access token olish.
  Future<Result<String>> refreshAccessToken();
}
