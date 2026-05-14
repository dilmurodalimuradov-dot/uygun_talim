import '../error/failures.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ResultFailure<T>;

  T? get dataOrNull => switch (this) {
    Success<T>(data: final d) => d,
    ResultFailure<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    ResultFailure<T>(failure: final f) => f,
  };

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success<T>(data: final d) => success(d),
      ResultFailure<T>(failure: final f) => failure(f),
    };
  }

  // ============ FOLD METODI QO'SHILDI ============
  R fold<R>({
    required R Function(Failure failure) onFailure,
    required R Function(T data) onSuccess,
  }) {
    return switch (this) {
      Success<T>(data: final d) => onSuccess(d),
      ResultFailure<T>(failure: final f) => onFailure(f),
    };
  }
// =============================================
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);
  final Failure failure;
}