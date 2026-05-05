
class ServerException implements Exception {
  ServerException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  NetworkException([this.message = 'Internetga ulanishda xatolik.']);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  TimeoutException([this.message = 'Server javob bermadi.']);
  final String message;

  @override
  String toString() => 'TimeoutException: $message';
}

class UnauthorizedException implements Exception {
  UnauthorizedException([this.message = 'Token yaroqsiz.']);
  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}

class CacheException implements Exception {
  CacheException(this.message);
  final String message;

  @override
  String toString() => 'CacheException: $message';
}
