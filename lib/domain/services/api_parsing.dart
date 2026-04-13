import 'dart:convert';

mixin ApiParsing {
  List<Map<String, dynamic>> decodeList(String body) {
    try {
      final decoded = jsonDecode(body);
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

  Map<String, dynamic> decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
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

  String extractErrorMessage(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] as String?;
        if (message != null && message.isNotEmpty) return message;
        final detail = decoded['detail'] as String?;
        if (detail != null && detail.isNotEmpty) return detail;
        final errorDescription = decoded['error_description'] as String?;
        if (errorDescription != null && errorDescription.isNotEmpty) {
          return errorDescription;
        }
        final error = decoded['error'] as String?;
        if (error != null && error.isNotEmpty) return error;
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

  int parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}