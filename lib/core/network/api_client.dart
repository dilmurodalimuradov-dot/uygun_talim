import 'dart:async' as async;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../error/exceptions.dart' as app_exc;

/// Bitta markaziy HTTP klient.
/// Xavfsiz URL qurilishi, debug logging, qulay xato chiqarish.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.defaultTimeout = ApiConstants.receiveTimeout,
    this.enableLogging = kDebugMode,
  }) : _client = httpClient ?? http.Client();

  final http.Client _client;
  final Duration defaultTimeout;
  final bool enableLogging;

  /// Har so'rovda token o'qiladi (yangilangan bo'lishi mumkin).
  Future<String?> Function()? tokenProvider;

  // =========================================================================
  // Public methods
  // =========================================================================

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
    String? baseUrlOverride,
    Duration? timeout,
  }) async {
    final uri = _buildUri(path, queryParameters, baseUrlOverride);
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    _log('GET', uri, headers);
    return _execute(
      () => _client.get(uri, headers: headers),
      timeout: timeout,
      uri: uri,
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
    String? baseUrlOverride,
    Duration? timeout,
  }) async {
    final uri = _buildUri(path, queryParameters, baseUrlOverride);
    final headers = await _buildHeaders(
      requiresAuth: requiresAuth,
      withContentType: true,
    );
    final jsonBody = body == null ? '{}' : jsonEncode(body);

    _log('POST', uri, headers, body: jsonBody);
    return _execute(
      () => _client.post(uri, headers: headers, body: jsonBody),
      timeout: timeout,
      uri: uri,
    );
  }

  /// Bir nechta endpoint'ni birma-bir sinab ko'rish (fallback).
  /// 404 bo'lsa keyingisiga o'tadi, boshqa xato — darhol throw qiladi.
  Future<dynamic> getFirstAvailable(
    List<String> paths, {
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
    String? baseUrlOverride,
    Duration? timeout,
  }) async {
    if (paths.isEmpty) {
      throw app_exc.ServerException('Endpoint ro\'yxati bo\'sh.');
    }

    http.Response? lastResponse;
    Object? lastError;

    for (final path in paths) {
      final uri = _buildUri(path, queryParameters, baseUrlOverride);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      _log('GET (try)', uri, headers);

      try {
        final response = await _client
            .get(uri, headers: headers)
            .timeout(timeout ?? defaultTimeout);
        lastResponse = response;
        _logResponse(response);

        if (response.statusCode == 404) {
          continue; // Keyingisini sinab ko'ramiz.
        }
        return _handleResponse(response);
      } on async.TimeoutException {
        lastError = app_exc.TimeoutException();
        continue;
      } on http.ClientException catch (e) {
        lastError = app_exc.NetworkException(e.message);
        continue;
      }
    }

    if (lastError != null) {
      throw lastError as Object;
    }

    if (lastResponse != null) {
      // Hamma endpoint 404 qaytardi — oxirgisini qayta ishlaymiz.
      return _handleResponse(lastResponse);
    }

    throw app_exc.NetworkException('Hech bir endpoint javob bermadi.');
  }

  /// Fayl yuklash uchun streamed response.
  Future<http.StreamedResponse> sendStreamed(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    bool followRedirects = true,
    int maxRedirects = 5,
  }) async {
    final request = http.Request(method, uri)
      ..followRedirects = followRedirects
      ..maxRedirects = maxRedirects;
    if (headers != null) request.headers.addAll(headers);
    return _client.send(request);
  }

  void dispose() => _client.close();

  // =========================================================================
  // Private helpers
  // =========================================================================

  /// URL'ni to'g'ri qurish.
  /// `path` absolyut URL bo'lishi mumkin yoki `/` bilan/bilansiz boshlanishi.
  /// Ikkala holatda ham to'g'ri URL hosil bo'ladi.
  Uri _buildUri(
    String path,
    Map<String, String>? queryParameters,
    String? baseUrlOverride,
  ) {
    Uri uri;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      uri = Uri.parse(path);
    } else {
      final base = baseUrlOverride ?? ApiConstants.baseUrl;
      // Ikki tomondan ham slash normalizatsiya — "https://host/api" + "/courses/"
      // → "https://host/api/courses/" shakliga keltiriladi.
      final cleanBase = base.endsWith('/')
          ? base.substring(0, base.length - 1)
          : base;
      final cleanPath = path.startsWith('/') ? path : '/$path';
      uri = Uri.parse('$cleanBase$cleanPath');
    }

    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParameters,
      });
    }

    return uri;
  }

  Future<Map<String, String>> _buildHeaders({
    required bool requiresAuth,
    bool withContentType = false,
  }) async {
    final headers = <String, String>{
      'accept': 'application/json',
      'X-CSRFTOKEN': ApiConstants.csrfToken,
    };

    if (withContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (requiresAuth) {
      final token = await tokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> _execute(
    Future<http.Response> Function() request, {
    Duration? timeout,
    required Uri uri,
  }) async {
    try {
      final response = await request().timeout(timeout ?? defaultTimeout);
      _logResponse(response);
      return _handleResponse(response);
    } on async.TimeoutException {
      throw app_exc.TimeoutException();
    } on http.ClientException catch (e) {
      throw app_exc.NetworkException(e.message);
    } on app_exc.ServerException {
      rethrow;
    } on app_exc.UnauthorizedException {
      rethrow;
    } on app_exc.TimeoutException {
      rethrow;
    } on app_exc.NetworkException {
      rethrow;
    } catch (e) {
      throw app_exc.NetworkException(e.toString());
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    final message = _extractError(response);

    if (statusCode == 401 || statusCode == 403) {
      throw app_exc.UnauthorizedException(message);
    }

    throw app_exc.ServerException(message, statusCode: statusCode);
  }

  /// Xato xabarini chiqarishda yanada ko'proq ma'lumot — status kod va
  /// agar JSON bo'lmasa, bodyning qisqa qismi.
  String _extractError(http.Response response) {
    final body = response.body;
    final statusCode = response.statusCode;

    if (body.isEmpty) {
      return 'Server $statusCode xatolik qaytardi.';
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'detail', 'error_description', 'error']) {
          final value = decoded[key];
          if (value is String && value.isNotEmpty) return value;
        }

        // `non_field_errors` ichidagi birinchi xabar
        final nonFieldErrors = decoded['non_field_errors'];
        if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
          final text = nonFieldErrors.first.toString();
          if (text.isNotEmpty) return text;
        }

        // Validation xatolari — birinchi topilgan fielddan olamiz
        for (final entry in decoded.entries) {
          final v = entry.value;
          if (v is List && v.isNotEmpty) {
            return '${entry.key}: ${v.first}';
          }
          if (v is String && v.isNotEmpty && v.length < 200) {
            return '${entry.key}: $v';
          }
        }
      }
    } catch (_) {
      // Javob JSON emas (masalan HTML error sahifasi)
    }

    // Status kodga qarab odamga tushunarli xabar
    switch (statusCode) {
      case 400:
        return 'Noto\'g\'ri so\'rov (400).';
      case 401:
        return 'Avtorizatsiyadan o\'tish kerak (401).';
      case 403:
        return 'Ruxsat yo\'q (403).';
      case 404:
        return 'Manzil topilmadi (404).';
      case 500:
        return 'Serverda ichki xatolik (500).';
      case 502:
      case 503:
        return 'Server vaqtincha ishlamayapti ($statusCode).';
      default:
        return 'Server xatolik qaytardi ($statusCode).';
    }
  }

  // ==================== Logging ====================

  void _log(String method, Uri uri, Map<String, String> headers,
      {String? body}) {
    if (!enableLogging) return;
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('→ $method ${uri.toString()}');
    final auth = headers['Authorization'];
    if (auth != null) {
      debugPrint('  Authorization: Bearer ${auth.substring(7, 20)}...');
    }
    if (body != null && body != '{}') {
      debugPrint('  Body: $body');
    }
  }

  void _logResponse(http.Response response) {
    if (!enableLogging) return;
    final body = response.body;
    final preview = body.length > 500 ? '${body.substring(0, 500)}...' : body;
    debugPrint('← ${response.statusCode} ${response.request?.url}');
    debugPrint('  $preview');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
