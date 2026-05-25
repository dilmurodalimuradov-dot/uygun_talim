import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class LessonProgressService {
  // POST /api/lesson-progress/ — API talab qilgan: lesson_id, position, duration
  // Server javobi: {success, last_position, max_position, is_fully_watched}
  // Muvaffaqiyatsiz bo'lsa null qaytaradi.
  Future<Map<String, dynamic>?> updateLessonProgress({
    required String lessonId,
    required String accessToken,
    required int position,
    required int duration,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/lesson-progress/');

      final body = <String, dynamic>{
        'lesson_id': lessonId,
        'position': position,
        'duration': duration,
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'X-CSRFTOKEN': ApiConstants.csrfToken,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}