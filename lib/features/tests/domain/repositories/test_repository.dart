import '../../../../core/utils/result.dart';
import '../entities/test_item.dart';

abstract class TestRepository {
  Future<Result<List<TestItem>>> getTests();
  Future<Result<Map<String, dynamic>>> getTestDetail(String id);
  Future<Result<Map<String, dynamic>>> submitTest(
    String id,
    Map<String, dynamic> payload,
  );
}
