import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_parser.dart';
import '../models/module_model.dart';

abstract class ModuleRemoteDataSource {
  Future<List<ModuleModel>> fetchModules(String courseId);
}

class ModuleRemoteDataSourceImpl implements ModuleRemoteDataSource {
  ModuleRemoteDataSourceImpl(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<List<ModuleModel>> fetchModules(String courseId) async {
    final response = await _apiClient.get(
      ApiConstants.modulesPath,
      queryParameters: {'course': courseId},
    );
    final decoded = JsonParser.decodeList(response);
    final modules = decoded.map(ModuleModel.fromJson).toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return a.title.compareTo(b.title);
      });
    return modules;
  }
}
