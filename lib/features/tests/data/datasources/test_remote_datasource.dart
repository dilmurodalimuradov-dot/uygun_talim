import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_parser.dart';
import '../models/test_item_model.dart';

abstract class TestRemoteDataSource {
  Future<List<TestItemModel>> fetchTests();
  Future<Map<String, dynamic>> fetchTestDetail(String id);
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
    final decoded = JsonParser.decodeList(response);
    return decoded.map(TestItemModel.fromJson).toList();
  }

  @override
  Future<Map<String, dynamic>> fetchTestDetail(String id) async {
    final response = await _apiClient.get(ApiConstants.testDetailPath(id));
    return JsonParser.decodeMap(response);
  }

  @override
  Future<Map<String, dynamic>> submitTest(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response =
        await _apiClient.post(ApiConstants.testSubmitPath(id), body: payload);
    return JsonParser.decodeMap(response);
  }
}
