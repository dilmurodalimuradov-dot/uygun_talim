import '../../core/di/service_locator.dart';
import '../../core/utils/usecase.dart';
import '../../features/tests/domain/entities/test_item.dart' as domain;
import '../../features/tests/domain/usecases/test_usecases.dart';

/// Testlar uchun yengil ko'prik sinf.
/// Token [ApiClient] interceptori orqali avtomatik qo'shiladi —
/// sahifalar tokenni qo'lda uzatmasligi kerak.
class TestItem {
  TestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.questionsCount,
  });

  final String id;
  final String title;
  final String description;
  final int duration;
  final int questionsCount;

  factory TestItem.fromDomain(domain.TestItem t) => TestItem(
    id: t.id,
    title: t.title,
    description: t.description,
    duration: t.duration,
    questionsCount: t.questionsCount,
  );
}

class TestService {
  /// Barcha testlarni yuklaydi.
  /// Token [ApiClient] → [ServiceLocator.apiClient.tokenProvider] orqali
  /// avtomatik qo'shiladi. Sahifalar tokenni qo'lda uzatmaydi.
  Future<List<TestItem>> fetchTests() async {
    final result = await ServiceLocator.getTests(const NoParams());
    return result.when(
      success: (list) => list.map(TestItem.fromDomain).toList(),
      failure: (f) => throw Exception(f.message),
    );
  }

  /// Bitta test tafsilotini yuklaydi.
  Future<Map<String, dynamic>> fetchTest(String id) async {
    final result = await ServiceLocator.getTestDetail(id);
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  /// Test javoblarini yuboradi.
  Future<Map<String, dynamic>> submitTest(
      String id,
      Map<String, dynamic> payload,
      ) async {
    final result = await ServiceLocator.submitTest(
      SubmitTestParams(id: id, payload: payload),
    );
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }
}
