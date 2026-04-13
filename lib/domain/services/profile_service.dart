import 'dart:convert';

import 'package:http/http.dart' as http;

class ProfileInfo {
  const ProfileInfo({
    required this.id,
    required this.studentIdNumber,
    required this.firstName,
    required this.secondName,
    required this.birthDate,
    required this.gender,
    required this.phoneNumber,
  });

  final String id;
  final String studentIdNumber;
  final String firstName;
  final String secondName;
  final String birthDate;
  final String gender;
  final String phoneNumber;

  String get fullName {
    final combined = '$firstName $secondName'.trim();
    return combined.isEmpty ? 'Foydalanuvchi' : combined;
  }
}

class ProfileService {
  ProfileService({
    http.Client? client,
    this.baseUrl = 'https://api.uyguntalim.tsue.uz/api-v1',
    this.csrfToken = 'x9Jv5GBLMZLVyTRu6rFmF2b8uORvppSDOHtWzbixuyB9RmgznaYKyNpuBDv3eOSb',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String csrfToken;

  Future<ProfileInfo> fetchProfile(String accessToken) async {
    final endpoints = <String>[
      'api-v1/account/me/',
      'api-v1/account/me',
      'account/me/',
      'account/me',
    ];
    http.Response? response;

    for (final endpoint in endpoints) {
      final uri = Uri.parse('$baseUrl/$endpoint');
      final currentResponse = await _client.get(
        uri,
        headers: _headers(accessToken),
      );
      response = currentResponse;
      if (currentResponse.statusCode != 404) {
        break;
      }
    }

    if (response == null) {
      throw Exception('Profil maʼlumotlarini olishda xatolik yuz berdi.');
    }

    final body = _decodeBody(response.body);
    if (response.statusCode == 200) {
      return _parseProfile(body);
    }

    final message = body['message'] as String?;
    throw Exception(message ?? 'Profil maʼlumotlarini olishda xatolik yuz berdi.');
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'X-CSRFTOKEN': csrfToken,
    };
  }

  ProfileInfo _parseProfile(Map<String, dynamic> data) {
    String genderValue = '';
    final rawGender = data['gender'];
    if (rawGender is Map<String, dynamic>) {
      genderValue = rawGender['name'] as String? ?? '';
    } else if (rawGender != null) {
      final asString = rawGender.toString();
      genderValue = _extractGenderName(asString);
    }

    return ProfileInfo(
      id: (data['id'] ?? '').toString(),
      studentIdNumber: (data['student_id_number'] ?? '').toString(),
      firstName: (data['first_name'] ?? '').toString(),
      secondName: (data['second_name'] ?? '').toString(),
      birthDate: (data['birth_date'] ?? '').toString(),
      gender: genderValue,
      phoneNumber: (data['phone_number'] ?? '').toString(),
    );
  }

  Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  String _extractGenderName(String raw) {
    final match =
        RegExp("name['\\\"]\\s*:\\s*['\\\"]([^'\\\"]+)").firstMatch(raw);
    if (match != null) {
      return match.group(1) ?? raw;
    }
    return raw;
  }
}