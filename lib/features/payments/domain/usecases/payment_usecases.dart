import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class GetMyPayments implements UseCase<List<Payment>, NoParams> {
  GetMyPayments(this._repository);
  final PaymentRepository _repository;

  @override
  Future<Result<List<Payment>>> call(NoParams params) =>
      _repository.getMyPayments();
}

class GetSuccessPayments implements UseCase<List<Payment>, NoParams> {
  GetSuccessPayments(this._repository);
  final PaymentRepository _repository;

  @override
  Future<Result<List<Payment>>> call(NoParams params) =>
      _repository.getSuccessPayments();
}

class CreatePayment
    implements UseCase<Map<String, dynamic>, Map<String, dynamic>> {
  CreatePayment(this._repository);
  final PaymentRepository _repository;

  @override
  Future<Result<Map<String, dynamic>>> call(Map<String, dynamic> payload) =>
      _repository.createPayment(payload);
}
