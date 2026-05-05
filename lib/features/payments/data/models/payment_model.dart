import '../../../../core/utils/json_parser.dart';
import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.amount,
    required super.currency,
    required super.status,
    required super.createdAt,
    super.courseTitle,
    super.courseImage,
    super.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final courseRaw = json['course'];
    final courseTitle =
        courseRaw is Map ? (courseRaw['title'] as String? ?? '') : '';
    final courseImage =
        courseRaw is Map ? (courseRaw['image'] as String? ?? '') : '';

    final amountRaw = json['amount'] ?? json['price'] ?? json['sum'] ?? json['total'];
    final amount = amountRaw != null ? amountRaw.toString() : '0';

    return PaymentModel(
      id: JsonParser.parseString(
        json['id'] ?? json['payment_id'] ?? json['transaction_id'],
      ),
      amount: amount,
      currency: JsonParser.parseString(
        json['currency'] ?? json['currency_code'] ?? 'UZS',
      ),
      status: JsonParser.parseString(
        json['status'] ?? json['state'] ?? json['payment_status'],
      ),
      createdAt: JsonParser.parseString(
        json['created_at'] ?? json['date'] ?? json['created'],
      ),
      courseTitle: courseTitle,
      courseImage: courseImage,
      paidAt: JsonParser.parseString(
        json['paid_at'] ?? json['payment_date'],
      ),
    );
  }
}
