import '../../core/di/service_locator.dart';
import '../../core/utils/usecase.dart';
import '../../features/tests/domain/entities/test_item.dart' as domain;
import '../../features/tests/domain/usecases/test_usecases.dart';

class TestItem {
  TestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.questionsCount,
    this.lessonId,
    this.moduleId,
  });

  final String id;
  final String title;
  final String description;
  final int duration;
  final int questionsCount;
  final String? lessonId;
  final String? moduleId;

  factory TestItem.fromDomain(domain.TestItem t) => TestItem(
    id: t.id,
    title: t.title,
    description: t.description,
    duration: t.duration,
    questionsCount: t.questionsCount,
    lessonId: t.lessonId,
    moduleId: t.moduleId,
  );
}

class TestService {
  String? _accessToken;

  void setAccessToken(String token) {
    _accessToken = token;
  }

  String? getAccessToken() => _accessToken;

  void clearAccessToken() {
    _accessToken = null;
  }

  Future<List<TestItem>> fetchTests() async {
    final result = await ServiceLocator.getTests(const NoParams());
    return result.when(
      success: (list) => list.map(TestItem.fromDomain).toList(),
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<List<TestItem>> fetchTestsByLesson(String lessonId) async {
    final result = await ServiceLocator.getTestsByLesson(lessonId);
    return result.when(
      success: (list) => list.map(TestItem.fromDomain).toList(),
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<List<TestItem>> fetchTestsByModule(String moduleId) async {
    final result = await ServiceLocator.getTestsByModule(moduleId);
    return result.when(
      success: (list) => list.map(TestItem.fromDomain).toList(),
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<Map<String, dynamic>> fetchTest(String id) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('Token topilmadi. Iltimos, qayta kiring.');
    }

    final result = await ServiceLocator.getTestDetail(id);
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<Map<String, dynamic>> startTest(String id) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('Token topilmadi. Iltimos, qayta kiring.');
    }

    final result = await ServiceLocator.startTest(id);
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  /// GET /lessons/{lessonId}/
  Future<Map<String, dynamic>> fetchLesson(String lessonId) async {
    try {
      final response = await ServiceLocator.apiClient.get('/lessons/$lessonId/');
      return response is Map<String, dynamic> ? response : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// POST /tests/{testId}/start/ — body sifatida dars obyektini yuboradi.
  Future<Map<String, dynamic>> startTestRaw(
    String testId,
    Map<String, dynamic> body,
  ) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('Token topilmadi. Iltimos, qayta kiring.');
    }
    final response = await ServiceLocator.apiClient.post(
      '/tests/$testId/start/',
      body: body,
    );
    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> submitTest(
      String id,
      Map<String, dynamic> payload,
      ) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('Token topilmadi. Iltimos, qayta kiring.');
    }

    final result = await ServiceLocator.submitTest(
      SubmitTestParams(id: id, payload: payload),
    );
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  /// Modul testlarini savollar bilan birga qaytaradi (list endpoint ishlatiladi).
  Future<List<Map<String, dynamic>>> fetchModuleTestsRaw(String moduleId) async {
    try {
      final response = await ServiceLocator.apiClient.get(
        '/tests/',
        queryParameters: {'module': moduleId},
      );
      if (response is List) {
        return response.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// GET /lessons/?module={moduleId} — test_id → status.passed
  Future<Map<String, bool>> fetchModulePassedStatus(String moduleId) async {
    try {
      final response = await ServiceLocator.apiClient.get(
        '/lessons/',
        queryParameters: {'module': moduleId},
      );
      if (response is! List) return {};
      final map = <String, bool>{};
      for (final item in response.whereType<Map<String, dynamic>>()) {
        final testId = item['test_id']?.toString();
        if (testId == null || testId.isEmpty) continue;
        final status = item['status'];
        map[testId] = status is Map && status['passed'] == true;
      }
      return map;
    } catch (_) {
      return {};
    }
  }
}