import '../../../../core/utils/result.dart';
import '../entities/test_item.dart';

abstract class TestRepository {
  Future<Result<List<TestItem>>> getTests();
  Future<Result<List<TestItem>>> getTestsByLesson(String lessonId);
  Future<Result<List<TestItem>>> getTestsByModule(String moduleId);
  Future<Result<Map<String, dynamic>>> getTestDetail(String id);
  Future<Result<Map<String, dynamic>>> startTest(String id);
  Future<Result<Map<String, dynamic>>> submitTest(
    String id,
    Map<String, dynamic> payload,
  );
}
