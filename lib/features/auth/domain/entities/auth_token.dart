/// Pure domain entity — data layerdan mustaqil.
/// Bu class package import qilmaydi, faqat Dart core.
class AuthToken {
  const AuthToken({
    required this.accessToken,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;

  bool get isValid => accessToken.isNotEmpty && accessToken.length >= 20;
}
