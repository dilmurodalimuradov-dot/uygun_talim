import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/error/exceptions.dart' as app_exc;

abstract class TokenLocalDataSource {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens({required String accessToken, String? refreshToken});
  Future<void> saveAccessToken(String token);
  Future<void> clearTokens();
  Future<bool> isTokenValid();
  Future<bool> isTokenExpired();
  Future<Map<String, dynamic>?> getTokenPayload();
}

class TokenLocalDataSourceImpl implements TokenLocalDataSource {
  TokenLocalDataSourceImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // ==================== Read ====================

  @override
  Future<String?> getAccessToken() => _readToken(StorageKeys.accessToken);

  @override
  Future<String?> getRefreshToken() => _readToken(StorageKeys.refreshToken);

  // ==================== Write ====================

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: StorageKeys.accessToken, value: accessToken),
        if (refreshToken != null && refreshToken.isNotEmpty)
          _storage.write(key: StorageKeys.refreshToken, value: refreshToken),
      ]);
      await _clearLegacyTokens();
    } catch (e) {
      throw app_exc.CacheException('Tokenni saqlashda xatolik: $e');
    }
  }

  @override
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.accessToken, value: token);
      await _clearLegacyToken(StorageKeys.accessToken);
    } catch (e) {
      throw app_exc.CacheException('Access tokenni saqlashda xatolik: $e');
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: StorageKeys.accessToken),
        _storage.delete(key: StorageKeys.refreshToken),
      ]);
      await _clearLegacyTokens();
    } catch (e) {
      throw app_exc.CacheException('Tokenni o\'chirishda xatolik: $e');
    }
  }

  // ==================== Validation ====================

  @override
  Future<bool> isTokenValid() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty || token.length < 20) return false;

    final parts = token.split('.');
    if (parts.length != 3) return false;

    return !(await isTokenExpired());
  }

  @override
  Future<bool> isTokenExpired() async {
    final payload = await getTokenPayload();
    if (payload == null || !payload.containsKey('exp')) return true;

    try {
      final exp = payload['exp'];
      final expMs = exp is int ? exp : int.tryParse(exp.toString()) ?? 0;
      final expiry = DateTime.fromMillisecondsSinceEpoch(expMs * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }

  @override
  Future<Map<String, dynamic>?> getTokenPayload() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null;

    return _decodePayload(parts[1]);
  }

  // ==================== Private ====================

  /// SecureStorage'dan o'qishni sinaydi, bo'lmasa SharedPreferences'dan
  /// eski tokenni topib, yangi joyga ko'chiradi (migration).
  Future<String?> _readToken(String key) async {
    try {
      final token = await _storage.read(key: key);
      if (token != null && token.isNotEmpty) return token;
    } on PlatformException {
      // SecureStorage ochilmasa, legacy'dan izlaymiz.
    }
    return _migrateLegacyToken(key);
  }

  Future<String?> _migrateLegacyToken(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(key);
      if (legacyToken == null || legacyToken.isEmpty) return null;

      await _storage.write(key: key, value: legacyToken);
      await prefs.remove(key);
      return legacyToken;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _decodePayload(String payload) {
    try {
      var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decoded = utf8.decode(base64Url.decode(normalized));
      final result = json.decode(decoded);
      return result is Map<String, dynamic> ? result : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearLegacyToken(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  Future<void> _clearLegacyTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(StorageKeys.accessToken),
        prefs.remove(StorageKeys.refreshToken),
      ]);
    } catch (_) {}
  }
}
