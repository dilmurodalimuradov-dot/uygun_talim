import '../../core/di/service_locator.dart';
import '../../core/utils/usecase.dart';
import '../../features/payments/domain/entities/payment.dart' as domain;

class Payment {
  Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String amount;
  final String currency;
  final String status;
  final String createdAt;

  factory Payment.fromDomain(domain.Payment p) => Payment(
        id: p.id,
        amount: p.amount,
        currency: p.currency,
        status: p.status,
        createdAt: p.createdAt,
      );
}

class PaymentService {
  Future<List<Payment>> fetchMyPayments(String token) async {
    final result = await ServiceLocator.getMyPayments(const NoParams());
    return result.when(
      success: (list) => list.map(Payment.fromDomain).toList(),
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<List<Payment>> fetchSuccessPayments(String token) async {

    final payments = await fetchMyPayments(token);
    return payments
        .where((p) =>
            p.status.toLowerCase() == 'success' ||
            p.status.toLowerCase() == 'completed' ||
            p.status.toLowerCase() == 'paid')
        .toList();
  }

  Future<Map<String, dynamic>> fetchPaymentStatus(
    String token,
    String paymentId,
  ) async {
    final result = await ServiceLocator.paymentRepository
        .getPaymentStatus(paymentId);
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<Map<String, dynamic>> createPayment(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final result = await ServiceLocator.createPayment(payload);
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }
}
