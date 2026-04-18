import '../../../../core/utils/result.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<Result<List<Payment>>> getMyPayments();
  Future<Result<List<Payment>>> getSuccessPayments();
  Future<Result<Map<String, dynamic>>> getPaymentStatus(String id);
  Future<Result<Map<String, dynamic>>> createPayment(
    Map<String, dynamic> payload,
  );
}
