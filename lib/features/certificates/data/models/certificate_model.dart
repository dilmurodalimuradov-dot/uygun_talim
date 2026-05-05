import '../../../../core/utils/json_parser.dart';
import '../../domain/entities/certificate.dart';

class CertificateModel extends Certificate {
  const CertificateModel({
    required super.id,
    required super.title,
    required super.issuedAt,
    required super.fileUrl,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: JsonParser.parseString(json['id']),
      title: JsonParser.parseString(
        json['title'] ?? json['name'] ?? json['course_title'],
      ),
      issuedAt: JsonParser.parseString(
        json['issued_at'] ?? json['created_at'] ?? json['date'],
      ),
      fileUrl: JsonParser.parseString(
        json['file'] ?? json['file_url'] ?? json['url'],
      ),
    );
  }
}