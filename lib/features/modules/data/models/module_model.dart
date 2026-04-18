import '../../../../core/utils/json_parser.dart';
import '../../domain/entities/module.dart';

class ModuleModel extends Module {
  const ModuleModel({
    required super.id,
    required super.title,
    required super.order,
    required super.lessonsCount,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: JsonParser.parseString(json['id']),
      title: JsonParser.parseString(json['title'] ?? json['name']),
      order: JsonParser.parseInt(
        json['order'] ?? json['position'] ?? json['index'],
      ),
      lessonsCount: JsonParser.parseInt(
        json['lessons_count'] ?? json['lesson_count'] ?? json['lessons'],
      ),
    );
  }
}
