import 'result.dart';

/// Har bir use case shu interfeysni amalga oshiradi.
/// Parameter yo'q bo'lsa — `NoParams()`.
abstract class UseCase<Type, Params> {
  Future<Result<Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
