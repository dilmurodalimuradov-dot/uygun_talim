// lib/features/tests/data/models/test_item_model.dart
import '../../../../core/utils/json_parser.dart';
import '../../domain/entities/test_item.dart';

class TestItemModel extends TestItem {
  const TestItemModel({
    required super.id,
    required super.title,
    required super.description,
    required super.duration,
    required super.questionsCount,
    super.lessonId,
    super.moduleId,
  });

  factory TestItemModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['test_id'] ?? json['uuid'];
    if (rawId == null) {
      throw FormatException('Test ID topilmadi. JSON: $json');
    }

    final rawTitle = json['title'] ?? json['name'] ?? json['subject'] ?? json['label'];
    if (rawTitle == null) {
      throw FormatException('Test title topilmadi. JSON: $json');
    }

    final rawDesc = json['description'] ?? json['desc'] ?? json['about'];
    final rawDuration = json['duration'] ?? json['time'] ?? json['duration_minutes'];
    // API list endpointida 'questions' array, detail da 'questions_count' kelishi mumkin
    final rawCount = json['questions_count'] ??
        json['questionsCount'] ??
        json['question_count'] ??
        json['total_questions'] ??
        (json['questions'] is List ? (json['questions'] as List).length : null);

    final rawLessonId = json['lesson'] ?? json['lesson_id'] ?? json['lesson_uuid'];
    final rawModuleId = json['module'] ?? json['module_id'] ?? json['module_uuid'];

    return TestItemModel(
      id: _parseId(rawId),
      title: _parseString(rawTitle, fieldName: 'title'),
      description: _parseString(rawDesc, defaultValue: ''),
      duration: _parseInt(rawDuration, defaultValue: 0),
      questionsCount: _parseInt(rawCount, defaultValue: 0),
      lessonId: rawLessonId != null ? _parseId(rawLessonId) : null,
      moduleId: rawModuleId != null ? _parseId(rawModuleId) : null,
    );
  }

  static String _parseId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toInt().toString();
    return value.toString();
  }

  static String _parseString(dynamic value, {String defaultValue = '', String? fieldName}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration': duration,
      'questions_count': questionsCount,
      if (lessonId != null) 'lesson_id': lessonId,
      if (moduleId != null) 'module_id': moduleId,
    };
  }

  TestItem toEntity() {
    return TestItem(
      id: id,
      title: title,
      description: description,
      duration: duration,
      questionsCount: questionsCount,
      lessonId: lessonId,
      moduleId: moduleId,
    );
  }
}
