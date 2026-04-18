import '../../../../core/utils/result.dart';
import '../entities/module.dart';

abstract class ModuleRepository {
  Future<Result<List<Module>>> getModules({required String courseId});
}
