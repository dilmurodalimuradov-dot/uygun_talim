import '../../../../core/utils/result.dart';
import '../entities/certificate.dart';

abstract class CertificateRepository {
  Future<Result<List<Certificate>>> getCertificates();
  Future<Result<List<Certificate>>> getMyCertificates();
  Future<Result<Map<String, dynamic>>> getCertificateDetail(String id);
}
