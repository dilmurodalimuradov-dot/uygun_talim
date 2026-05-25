// lib/features/tests/domain/usecases/test_usecases.dart
import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/test_item.dart';
import '../repositories/test_repository.dart';

class GetTests implements UseCase<List<TestItem>, NoParams> {
  GetTests(this._repository);
  final TestRepository _repository;

  @override
  Future<Result<List<TestItem>>> call(NoParams params) =>
      _repository.getTests();
}

class GetTestsByLesson implements UseCase<List<TestItem>, String> {
  GetTestsByLesson(this._repository);
  final TestRepository _repository;

  @override
  Future<Result<List<TestItem>>> call(String lessonId) =>
      _repository.getTestsByLesson(lessonId);
}

class GetTestsByModule implements UseCase<List<TestItem>, String> {
  GetTestsByModule(this._repository);
  final TestRepository _repository;

  @override
  Future<Result<List<TestItem>>> call(String moduleId) =>
      _repository.getTestsByModule(moduleId);
}

class GetTestDetail implements UseCase<Map<String, dynamic>, String> {
  GetTestDetail(this._repository);
  final TestRepository _repository;

  @override
  Future<Result<Map<String, dynamic>>> call(String id) =>
      _repository.getTestDetail(id);
}

class StartTest implements UseCase<Map<String, dynamic>, String> {
  StartTest(this._repository);
  final TestRepository _repository;

  @override
  Future<Result<Map<String, dynamic>>> call(String id) =>
      _repository.startTest(id);
}

class SubmitTestParams {
  const SubmitTestParams({required this.id, required this.payload});
  final String id;
  final Map<String, dynamic> payload;
}

class SubmitTest implements UseCase<Map<String, dynamic>, SubmitTestParams> {
  SubmitTest(this._repository);
  final TestRepository _repository;

  @override
  Future<Result<Map<String, dynamic>>> call(SubmitTestParams params) =>
      _repository.submitTest(params.id, params.payload);
}
