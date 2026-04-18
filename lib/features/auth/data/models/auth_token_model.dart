import '../../domain/entities/auth_token.dart';

/// Data qatlami modeli — JSON bilan ishlaydi, entity'ga aylantiradi.
class AuthTokenModel extends AuthToken {
  const AuthTokenModel({
    required super.accessToken,
    super.refreshToken,
  });

  /// Backend javobida tokenlar turli joylarda bo'lishi mumkin:
  /// `{access, refresh}`, `{access_token, refresh_token}`, `{data: {tokens: {...}}}` va h.k.
  /// Shularning barchasini rekursiv izlab, topgandan keyin qaytaradi.
  factory AuthTokenModel.fromJson(Map<String, dynamic> json) {
    String? access;
    String? refresh;

    void readTokensFromMap(Map<String, dynamic> source) {
      access ??= source['access'] as String? ??
          source['access_token'] as String? ??
          source['token'] as String?;
      refresh ??= source['refresh'] as String? ??
          source['refresh_token'] as String?;
    }

    readTokensFromMap(json);

    final rootTokens = json['tokens'];
    if (rootTokens is Map<String, dynamic>) readTokensFromMap(rootTokens);

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      readTokensFromMap(data);
      final dataTokens = data['tokens'];
      if (dataTokens is Map<String, dynamic>) readTokensFromMap(dataTokens);
    }

    if (access == null || access!.isEmpty) {
      throw Exception('Javobdan access token topilmadi.');
    }

    return AuthTokenModel(
      accessToken: access!,
      refreshToken: refresh,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        if (refreshToken != null) 'refresh_token': refreshToken,
      };
}
