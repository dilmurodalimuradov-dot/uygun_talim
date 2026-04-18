import '../../core/di/service_locator.dart';
import '../../core/utils/usecase.dart';
import '../../features/profile/domain/entities/profile_info.dart' as domain;

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

  factory ProfileInfo.fromDomain(domain.ProfileInfo p) => ProfileInfo(
        id: p.id,
        studentIdNumber: p.studentIdNumber,
        firstName: p.firstName,
        secondName: p.secondName,
        birthDate: p.birthDate,
        gender: p.gender,
        phoneNumber: p.phoneNumber,
      );
}

class ProfileService {
  Future<ProfileInfo> fetchProfile(String token) async {
    final result = await ServiceLocator.getProfile(const NoParams());
    return result.when(
      success: ProfileInfo.fromDomain,
      failure: (f) => throw Exception(f.message),
    );
  }
}
