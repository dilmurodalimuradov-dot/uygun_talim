import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_parser.dart';
import '../models/course_model.dart';

abstract class CourseRemoteDataSource {
  Future<List<CourseModel>> fetchCourses();
  Future<CourseModel> fetchCourseDetail(String id);
  Future<void> startCourse(String id);
  Future<Map<String, dynamic>> fetchCourseProgress(String id);
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  CourseRemoteDataSourceImpl(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<List<CourseModel>> fetchCourses() async {
    final response = await _apiClient.get(ApiConstants.coursesPath);
    final decoded = JsonParser.decodeList(response);
    return decoded.map(CourseModel.fromJson).toList();
  }

  @override
  Future<CourseModel> fetchCourseDetail(String id) async {
    final response =
        await _apiClient.get(ApiConstants.courseDetailPath(id));
    final decoded = JsonParser.decodeMap(response);
    return CourseModel.fromJson(decoded);
  }

  @override
  Future<void> startCourse(String id) async {
    await _apiClient.post(ApiConstants.courseStartPath(id));
  }

  @override
  Future<Map<String, dynamic>> fetchCourseProgress(String id) async {
    final response =
        await _apiClient.get(ApiConstants.courseProgressPath(id));
    return JsonParser.decodeMap(response);
  }
}
