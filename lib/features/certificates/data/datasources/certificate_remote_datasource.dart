import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_parser.dart';
import '../models/certificate_model.dart';

abstract class CertificateRemoteDataSource {
  Future<List<CertificateModel>> fetchCertificates();
  Future<List<CertificateModel>> fetchMyCertificates();
  Future<Map<String, dynamic>> fetchCertificateDetail(String id);
}

class CertificateRemoteDataSourceImpl implements CertificateRemoteDataSource {
  CertificateRemoteDataSourceImpl(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<List<CertificateModel>> fetchCertificates() async {
    final response = await _apiClient.get(ApiConstants.certificatesPath);
    return JsonParser.decodeList(response)
        .map(CertificateModel.fromJson)
        .toList();
  }

  @override
  Future<List<CertificateModel>> fetchMyCertificates() async {
    final response = await _apiClient.get(ApiConstants.myCertificatesPath);
    return JsonParser.decodeList(response)
        .map(CertificateModel.fromJson)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> fetchCertificateDetail(String id) async {
    final response =
        await _apiClient.get(ApiConstants.certificateDetailPath(id));
    return JsonParser.decodeMap(response);
  }
}
