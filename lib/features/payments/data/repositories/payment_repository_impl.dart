import '../../../../core/error/exceptions.dart' as app_exc;
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._remote);
  final PaymentRemoteDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on app_exc.UnauthorizedException catch (e) {
      return ResultFailure(UnauthorizedFailure(e.message));
    } on app_exc.ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on app_exc.TimeoutException catch (e) {
      return ResultFailure(TimeoutFailure(e.message));
    } on app_exc.NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Payment>>> getMyPayments() =>
      _guard(() => _remote.fetchMyPayments().then((v) => v.whereType<Payment>().toList()));

  @override
  Future<Result<List<Payment>>> getSuccessPayments() =>
      _guard(() => _remote.fetchSuccessPayments().then((v) => v.whereType<Payment>().toList()));

  @override
  Future<Result<Map<String, dynamic>>> getPaymentStatus(String id) =>
      _guard(() => _remote.fetchPaymentStatus(id));

  @override
  Future<Result<Map<String, dynamic>>> createPayment(
    Map<String, dynamic> payload,
  ) =>
      _guard(() => _remote.createPayment(payload));
}
