import '../../core/di/service_locator.dart';
import '../../features/modules/domain/entities/module.dart' as domain;
import '../../core/constants/api_constants.dart';


class Module {
  Module({
    required this.id,
    required this.title,
    required this.order,
    required this.lessonsCount,
  });

  final String id;
  final String title;
  final int order;
  final int lessonsCount;

  factory Module.fromDomain(domain.Module m) => Module(
        id: m.id,
        title: m.title,
        order: m.order,
        lessonsCount: m.lessonsCount,
      );
}

class ModuleService {
  // Token argument'i qabul qilinadi lekin ishlatilmaydi — ApiClient
  // avtomatik auth qiladi.
  Future<List<Module>> fetchModules(
    String token, {
    required String courseId,
  }) async {
    final result = await ServiceLocator.getModules(courseId);
    return result.when(
      success: (list) => list.map(Module.fromDomain).toList(),
      failure: (f) => throw Exception(f.message),
    );
  }

  String get csrfToken => ApiConstants.csrfToken;
}
