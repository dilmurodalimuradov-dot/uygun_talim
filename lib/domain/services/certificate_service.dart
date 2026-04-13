import 'package:http/http.dart' as http;
import 'package:pr/domain/services/api_parsing.dart';

class Certificate {
  Certificate({
    required this.id,
    required this.title,
    required this.issuedAt,
    required this.fileUrl,
    required this.raw,
  });

  final String id;
  final String title;
  final String issuedAt;
  final String fileUrl;
  final Map<String, dynamic> raw;

  factory Certificate.fromMap(Map<String, dynamic> data) {
    return Certificate(
      id: (data['id'] ?? '').toString(),
      title: (data['title'] ?? data['name'] ?? data['course_title'] ?? '').toString(),
      issuedAt: (data['issued_at'] ?? data['created_at'] ?? data['date'] ?? '').toString(),
      fileUrl: (data['file'] ?? data['file_url'] ?? data['url'] ?? '').toString(),
      raw: data,
    );
  }
}

class CertificateService with ApiParsing {
  CertificateService({
    http.Client? client,
    this.baseUrl = 'https://api.uyguntalim.tsue.uz/api',
    this.csrfToken = 'x9Jv5GBLMZLVyTRu6rFmF2b8uORvppSDOHtWzbixuyB9RmgznaYKyNpuBDv3eOSb',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String csrfToken;

  Future<List<Certificate>> fetchCertificates(String accessToken) async {
    final uri = Uri.parse('$baseUrl/certificates/');
    final response = await _client.get(uri, headers: _headers(accessToken));
    if (response.statusCode != 200) {
      throw Exception(
        extractErrorMessage(
          response.body,
          fallback: 'Sertifikatlarni olishda xatolik yuz berdi.',
        ),
      );
    }
    final decoded = decodeList(response.body);
    return decoded.map(Certificate.fromMap).toList();
  }

  Future<List<Certificate>> fetchMyCertificates(String accessToken) async {
    final uri = Uri.parse('$baseUrl/certificates/my/');
    final response = await _client.get(uri, headers: _headers(accessToken));
    if (response.statusCode != 200) {
      throw Exception(
        extractErrorMessage(
          response.body,
          fallback: 'Sertifikatlarni olishda xatolik yuz berdi.',
        ),
      );
    }
    final decoded = decodeList(response.body);
    return decoded.map(Certificate.fromMap).toList();
  }

  Future<Map<String, dynamic>> fetchCertificate(
      String accessToken,
      String id,
      ) async {
    final uri = Uri.parse('$baseUrl/certificates/$id/');
    final response = await _client.get(uri, headers: _headers(accessToken));
    if (response.statusCode != 200) {
      throw Exception(
        extractErrorMessage(
          response.body,
          fallback: 'Sertifikat maʼlumotlarini olishda xatolik yuz berdi.',
        ),
      );
    }
    return decodeMap(response.body);
  }

  Future<http.StreamedResponse> downloadCertificateFile(
      String accessToken,
      String fileUrl,
      ) async {
    final uri = Uri.parse(
      fileUrl.startsWith('http')
          ? fileUrl
          : 'https://api.uyguntalim.tsue.uz$fileUrl',
    );

    final req1 = http.Request('GET', uri)
      ..followRedirects = true
      ..maxRedirects = 5
      ..headers.addAll({
        'User-Agent':
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': '*/*',
      });
    final res1 = await _client.send(req1);
    if (res1.statusCode == 200) return res1;
    await res1.stream.drain();

    final req2 = http.Request('GET', uri)
      ..followRedirects = true
      ..maxRedirects = 5
      ..headers.addAll({
        'User-Agent':
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': '*/*',
        'Authorization': 'Bearer $accessToken',
        'X-CSRFTOKEN': csrfToken,
      });
    return _client.send(req2);
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'X-CSRFTOKEN': csrfToken,
    };
  }
}