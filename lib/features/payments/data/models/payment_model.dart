import '../../../../core/utils/json_parser.dart';
import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.amount,
    required super.currency,
    required super.status,
    required super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: JsonParser.parseString(json['id']),
      amount: JsonParser.parseString(
        json['amount'] ?? json['price'] ?? json['sum'],
      ),
      currency: JsonParser.parseString(
        json['currency'] ?? json['currency_code'],
      ),
      status: JsonParser.parseString(json['status'] ?? json['state']),
      createdAt: JsonParser.parseString(json['created_at'] ?? json['date']),
    );
  }
}
