import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class TokenStorageService {
  TokenStorageService({FlutterSecureStorage? storage, String? baseUrl})
      : _storage = storage ?? const FlutterSecureStorage(),
        _baseUrl = baseUrl ?? 'https://api.uyguntalim.tsue.uz';

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  final String _baseUrl;
  Timer? _refreshTimer;

  // Token o'qish
  Future<String?> readAccessToken() async {
    return _readToken(_accessTokenKey);
  }

  Future<String?> readRefreshToken() async {
    return _readToken(_refreshTokenKey);
  }

  // Token saqlash
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      if (refreshToken != null && refreshToken.isNotEmpty)
        _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
    await _clearLegacyTokens();

    // Auto-refreshni qayta ishga tushirish
    // (agar kerak bo'lsa, callback bilan)
  }

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
    await _clearLegacyToken(_accessTokenKey);
  }

  // Token o'chirish
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
    await _clearLegacyTokens();
    _stopAutoRefresh();
  }

  // Token validatsiyasi
  Future<bool> isValidToken() async {
    final token = await readAccessToken();
    if (token == null || token.isEmpty) return false;

    if (token.length < 20) return false;

    final parts = token.split('.');
    if (parts.length != 3) return false;

    try {
      final isExpired = await isTokenExpired();
      return !isExpired;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isTokenExpired() async {
    final token = await readAccessToken();
    if (token == null || token.isEmpty) return true;

    try {
      final payload = await getTokenPayload();
      if (payload == null || !payload.containsKey('exp')) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return true;
    }
  }

  Future<Map<String, dynamic>?> getTokenPayload() async {
    final token = await readAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      return _decodePayload(parts[1]);
    } catch (e) {
      return null;
    }
  }

  // Token yangilash
  Future<String?> refreshToken() async {
    final refreshToken = await readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access_token'] ?? data['accessToken'];

        if (newAccessToken != null) {
          await saveAccessToken(newAccessToken);
          return newAccessToken;
        }
      } else if (response.statusCode == 401) {
        await clearTokens();
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
    return null;
  }

  // Private helpers
  Future<String?> _readToken(String key) async {
    try {
      final token = await _storage.read(key: key);
      if (token != null && token.isNotEmpty) return token;
    } on PlatformException catch (e) {
      print('SecureStorage read error for $key: ${e.message}');
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
    } catch (e) {
      print('Migration error for $key: $e');
      return null;
    }
  }

  Map<String, dynamic> _decodePayload(String payload) {
    try {
      String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded);
    } catch (e) {
      return {};
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
        prefs.remove(_accessTokenKey),
        prefs.remove(_refreshTokenKey),
      ]);
    } catch (_) {}
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void dispose() {
    _stopAutoRefresh();
  }
}