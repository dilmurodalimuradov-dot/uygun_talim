import '../../../../core/utils/json_parser.dart';
import '../../domain/entities/profile_info.dart';

class ProfileInfoModel extends ProfileInfo {
  const ProfileInfoModel({
    required super.id,
    required super.studentIdNumber,
    required super.firstName,
    required super.secondName,
    required super.birthDate,
    required super.gender,
    required super.phoneNumber,
  });

  factory ProfileInfoModel.fromJson(Map<String, dynamic> json) {
    String genderValue = '';
    final rawGender = json['gender'];
    if (rawGender is Map<String, dynamic>) {
      genderValue = rawGender['name'] as String? ?? '';
    } else if (rawGender != null) {
      final asString = rawGender.toString();
      final match = RegExp(r"name['\x22]\s*:\s*['\x22]([^'\x22]+)")
          .firstMatch(asString);
      genderValue = match?.group(1) ?? asString;
    }

    return ProfileInfoModel(
      id: JsonParser.parseString(json['id']),
      studentIdNumber: JsonParser.parseString(json['student_id_number']),
      firstName: JsonParser.parseString(json['first_name']),
      secondName: JsonParser.parseString(json['second_name']),
      birthDate: JsonParser.parseString(json['birth_date']),
      gender: genderValue,
      phoneNumber: JsonParser.parseString(json['phone_number']),
    );
  }
}
