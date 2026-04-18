import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/module.dart';
import '../repositories/module_repository.dart';

class GetModules implements UseCase<List<Module>, String> {
  GetModules(this._repository);
  final ModuleRepository _repository;

  @override
  Future<Result<List<Module>>> call(String courseId) =>
      _repository.getModules(courseId: courseId);
}
