import 'dart:convert';

/// JSON parsing yordamchisi.
/// Ilgarigi `ApiParsing` mixin'ning o'rnida turadi.
/// Har joyda takrorlanmasligi uchun shu yerga ko'chirildi.
class JsonParser {
  JsonParser._();

  /// Javob `List`, yoki `{results: [...]}`, yoki `{data: [...]}` bo'lishi mumkin.
  static List<Map<String, dynamic>> decodeList(dynamic body) {
    try {
      final decoded = body is String ? jsonDecode(body) : body;
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
      if (decoded is Map<String, dynamic>) {
        final results = decoded['results'];
        if (results is List) {
          return results.whereType<Map<String, dynamic>>().toList();
        }
        final data = decoded['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  /// Javob `{...}` yoki `{data: {...}}` bo'lishi mumkin.
  static Map<String, dynamic> decodeMap(dynamic body) {
    try {
      final decoded = body is String ? jsonDecode(body) : body;
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is Map<String, dynamic> && data.isNotEmpty) {
          return data;
        }
        return decoded;
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  /// Backenddan kelgan xato xabarini olish.
  static String extractErrorMessage(
    dynamic body, {
    required String fallback,
  }) {
    try {
      final decoded = body is String ? jsonDecode(body) : body;
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'detail', 'error_description', 'error']) {
          final value = decoded[key];
          if (value is String && value.isNotEmpty) return value;
        }

        final nonFieldErrors = decoded['non_field_errors'];
        if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
          final text = nonFieldErrors.first.toString();
          if (text.isNotEmpty) return text;
        }

        for (final key in ['lesson_id', 'position', 'duration']) {
          final errors = decoded[key];
          if (errors is List && errors.isNotEmpty) {
            final text = errors.first.toString();
            if (text.isNotEmpty) return text;
          }
        }
      }
    } catch (_) {}
    return fallback;
  }

  /// String/int/null — hammasini xavfsiz int'ga aylantiradi.
  static int parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static bool parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}
