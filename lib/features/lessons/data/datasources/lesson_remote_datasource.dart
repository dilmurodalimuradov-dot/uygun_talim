import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_parser.dart';
import '../models/lesson_model.dart';

abstract class LessonRemoteDataSource {
  Future<List<LessonModel>> fetchLessons(String moduleId);
}

class LessonRemoteDataSourceImpl implements LessonRemoteDataSource {
  LessonRemoteDataSourceImpl(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<List<LessonModel>> fetchLessons(String moduleId) async {
    final response = await _apiClient.get(
      ApiConstants.lessonsPath,
      queryParameters: {'module': moduleId},
    );
    final decoded = JsonParser.decodeList(response);
    final lessons = decoded.map(LessonModel.fromJson).toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return a.title.compareTo(b.title);
      });
    return lessons;
  }
}
