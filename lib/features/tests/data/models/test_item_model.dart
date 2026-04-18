import '../../../../core/utils/json_parser.dart';
import '../../domain/entities/test_item.dart';

class TestItemModel extends TestItem {
  const TestItemModel({
    required super.id,
    required super.title,
    required super.description,
    required super.duration,
    required super.questionsCount,
  });

  factory TestItemModel.fromJson(Map<String, dynamic> json) {
    return TestItemModel(
      id: JsonParser.parseString(json['id']),
      title: JsonParser.parseString(
        json['title'] ?? json['name'] ?? json['subject'],
      ),
      description: JsonParser.parseString(json['description']),
      duration: JsonParser.parseInt(json['duration'] ?? json['time']),
      questionsCount: JsonParser.parseInt(
        json['questions_count'] ?? json['questionsCount'],
      ),
    );
  }
}
