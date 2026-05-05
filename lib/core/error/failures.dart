
abstract class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Internet bilan bogʻlanishda xatolik.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Server javob bermadi.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sessiya tugadi. Qayta kiring.']);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Nomaʼlum xatolik yuz berdi.']);
}
