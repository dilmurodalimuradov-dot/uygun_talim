import '../../core/constants/api_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/usecase.dart';
import '../../features/certificates/domain/entities/certificate.dart'
    as domain;

class Certificate {
  Certificate({
    required this.id,
    required this.title,
    required this.issuedAt,
    required this.fileUrl,
  });

  final String id;
  final String title;
  final String issuedAt;
  final String fileUrl;

  factory Certificate.fromDomain(domain.Certificate c) => Certificate(
        id: c.id,
        title: c.title,
        issuedAt: c.issuedAt,
        fileUrl: c.fileUrl,
      );
}

class CertificateService {
  Future<List<Certificate>> fetchCertificates(String token) async {
    final result =
        await ServiceLocator.getMyCertificates(const NoParams());
    return result.when(
      success: (list) => list.map(Certificate.fromDomain).toList(),
      failure: (f) => throw Exception(f.message),
    );
  }

  String get csrfToken => ApiConstants.csrfToken;
}
