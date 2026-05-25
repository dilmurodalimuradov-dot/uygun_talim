import '../../../../core/utils/json_parser.dart';
import '../../../../core/utils/url_helper.dart';
import '../../domain/entities/lesson.dart';

class LessonModel extends Lesson {
  const LessonModel({
    required super.id,
    required super.title,
    required super.order,
    required super.description,
    required super.videoSource,
    super.testId,
    required super.hasTest,
    required super.isFullyWatched,
    required super.isCompleted,
    super.testPassed,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] as Map<String, dynamic>?;
    final isFullyWatched = progress?['is_fully_watched'] == true;
    final isCompleted = progress?['is_completed'] == true;
    final status = json['status'] as Map<String, dynamic>?;
    final testPassed = status?['passed'] == true;

    return LessonModel(
      id: JsonParser.parseString(json['id']),
      title: JsonParser.parseString(json['title'] ?? json['name']),
      order: JsonParser.parseInt(
        json['order'] ?? json['position'] ?? json['index'],
      ),
      description: JsonParser.parseString(
        json['description'] ?? json['content'],
      ),
      videoSource: UrlHelper.normalizeMediaUrl(_extractVideoSource(json)),
      testId: json['test_id']?.toString(),
      hasTest: json['has_test'] == true || json['test_id'] != null,
      isFullyWatched: isFullyWatched,
      isCompleted: isCompleted,
      testPassed: testPassed,
    );
  }

  static String _extractVideoSource(Map<String, dynamic> data) {
    const keys = [
      'video',
      'video_url',
      'video_source',
      'video_file',
      'file',
      'url',
      'source',
      'media',
    ];

    for (final key in keys) {
      final extracted = _extractString(data[key]);
      if (extracted.isNotEmpty) return extracted;
    }

    for (final value in data.values) {
      final extracted = _extractString(value);
      if (extracted.isNotEmpty &&
          (extracted.contains('.mp4') ||
              extracted.contains('.m3u8') ||
              extracted.startsWith('http'))) {
        return extracted;
      }
    }

    return '';
  }

  static String _extractString(dynamic value) {
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      for (final nestedKey in ['url', 'file', 'video', 'src', 'source']) {
        final nested = value[nestedKey];
        if (nested is String && nested.isNotEmpty) return nested;
      }
    }
    return '';
  }
}