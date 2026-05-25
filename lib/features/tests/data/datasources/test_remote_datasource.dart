import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_parser.dart';
import '../models/test_item_model.dart';

abstract class TestRemoteDataSource {
  Future<List<TestItemModel>> fetchTests();
  Future<List<TestItemModel>> fetchTestsByLesson(String lessonId);
  Future<List<TestItemModel>> fetchTestsByModule(String moduleId);
  Future<Map<String, dynamic>> fetchTestDetail(String id);
  Future<Map<String, dynamic>> startTest(String id);
  Future<Map<String, dynamic>> submitTest(
      String id,
      Map<String, dynamic> payload,
      );
}

class TestRemoteDataSourceImpl implements TestRemoteDataSource {
  TestRemoteDataSourceImpl(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<List<TestItemModel>> fetchTests() async {
    final response = await _apiClient.get(ApiConstants.testsPath);
    return _parseList(response);
  }

  @override
  Future<List<TestItemModel>> fetchTestsByLesson(String lessonId) async {
    // Avval ?lesson= query param bilan urinib ko'ramiz
    try {
      final response = await _apiClient.get(
        ApiConstants.testsPath,
        queryParameters: {'lesson': lessonId},
      );
      return _parseList(response);
    } catch (_) {
      // Agar ishlamasa bo'sh qaytaramiz
      return [];
    }
  }

  @override
  Future<List<TestItemModel>> fetchTestsByModule(String moduleId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.testsPath,
        queryParameters: {'module': moduleId},
      );
      return _parseList(response);
    } catch (_) {
      return [];
    }
  }

  List<TestItemModel> _parseList(dynamic response) {
    final decoded = JsonParser.decodeList(response);
    return decoded.map((json) => TestItemModel.fromJson(json)).toList();
  }

  @override
  Future<Map<String, dynamic>> fetchTestDetail(String id) async {
    final response = await _apiClient.get(ApiConstants.testDetailPath(id));
    return JsonParser.decodeMap(response);
  }

  @override
  Future<Map<String, dynamic>> startTest(String id) async {
    final response = await _apiClient.post(ApiConstants.testStartPath(id));
    return JsonParser.decodeMap(response);
  }

  @override
  Future<Map<String, dynamic>> submitTest(
      String id,
      Map<String, dynamic> payload,
      ) async {
    final response = await _apiClient.post(
      ApiConstants.testSubmitPath(id),
      body: payload,
    );
    return JsonParser.decodeMap(response);
  }
}
