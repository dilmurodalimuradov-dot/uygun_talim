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
    this.courseTitle = '',
    this.courseImage = '',
    this.paidAt = '',
  });

  final String id;
  final String amount;
  final String currency;
  final String status;
  final String createdAt;
  final String courseTitle;
  final String courseImage;
  final String paidAt;

  factory Payment.fromDomain(domain.Payment p) => Payment(
        id: p.id,
        amount: p.amount,
        currency: p.currency,
        status: p.status,
        createdAt: p.createdAt,
        courseTitle: p.courseTitle,
        courseImage: p.courseImage,
        paidAt: p.paidAt,
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
    final result = await ServiceLocator.getSuccessPayments(const NoParams());
    return result.when(
      success: (list) => list.map(Payment.fromDomain).toList(),
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<Map<String, dynamic>> fetchPaymentStatus(
    String token,
    String paymentId,
  ) async {
    final result =
        await ServiceLocator.paymentRepository.getPaymentStatus(paymentId);
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

  /// To'lov yaratib checkout URL ini qaytaradi.
  /// URL createPayment javobida bo'lmasa status endpointidan oladi.
  Future<String> createPaymentAndGetUrl(
    String token,
    String courseId,
  ) async {
    final response = await createPayment(token, {'course_id': courseId});

    final directUrl = _extractPaymentUrl(response);
    if (directUrl.isNotEmpty) return directUrl;

    final paymentId = _extractPaymentId(response);
    if (paymentId.isNotEmpty) {
      try {
        final statusData = await fetchPaymentStatus(token, paymentId);
        final statusUrl = _extractPaymentUrl(statusData);
        if (statusUrl.isNotEmpty) return statusUrl;
      } catch (_) {}
    }

    throw Exception("To'lov havolasi kelmadi.");
  }

  static String _extractPaymentUrl(Map<String, dynamic> data) {
    const keys = [
      'url', 'payment_url', 'pay_url', 'checkout_url', 'deeplink',
      'link', 'redirect_url', 'redirect', 'payment_link', 'payme_url',
      'transaction_url', 'invoice_url', 'pay_link',
    ];
    for (final key in keys) {
      final v = data[key];
      if (v is String && _isPaymentUrl(v)) return v.trim();
    }
    for (final v in data.values) {
      if (v is String && _isPaymentUrl(v)) return v.trim();
      if (v is Map<String, dynamic>) {
        final nested = _extractPaymentUrl(v);
        if (nested.isNotEmpty) return nested;
      }
    }
    return '';
  }

  static String _extractPaymentId(Map<String, dynamic> data) {
    const keys = ['id', 'payment_id', 'transaction_id', 'order_id'];
    for (final key in keys) {
      final v = data[key];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty && s != 'null') return s;
      }
    }
    return '';
  }

  static bool _isPaymentUrl(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    return v.startsWith('https://') ||
        v.startsWith('http://') ||
        v.startsWith('payme://') ||
        v.startsWith('uzum://') ||
        v.startsWith('click://');
  }
}
