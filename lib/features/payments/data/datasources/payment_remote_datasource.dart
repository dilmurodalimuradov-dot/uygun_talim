import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_parser.dart';
import '../models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<List<PaymentModel>> fetchMyPayments();
  Future<List<PaymentModel>> fetchSuccessPayments();
  Future<Map<String, dynamic>> fetchPaymentStatus(String id);
  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> payload);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  PaymentRemoteDataSourceImpl(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<List<PaymentModel>> fetchMyPayments() async {
    final response = await _apiClient.get(ApiConstants.myPaymentsPath);
    return _parseList(response).map(PaymentModel.fromJson).toList();
  }

  @override
  Future<List<PaymentModel>> fetchSuccessPayments() async {
    final response = await _apiClient.get(ApiConstants.myPaymentsPath);
    final all = _parseList(response).map(PaymentModel.fromJson).toList();
    return all.where((p) => p.isSuccess).toList();
  }

  @override
  Future<Map<String, dynamic>> fetchPaymentStatus(String id) async {
    final response = await _apiClient.get(ApiConstants.paymentStatusPath(id));
    return JsonParser.decodeMap(response);
  }

  @override
  Future<Map<String, dynamic>> createPayment(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.createPaymentPath,
      body: payload,
    );
    return JsonParser.decodeMap(response);
  }

  List<Map<String, dynamic>> _parseList(dynamic response) {
    if (response is Map<String, dynamic>) {
      final payments = response['payments'];
      if (payments is List) {
        return payments.whereType<Map<String, dynamic>>().toList();
      }
    }
    return JsonParser.decodeList(response);
  }
}
