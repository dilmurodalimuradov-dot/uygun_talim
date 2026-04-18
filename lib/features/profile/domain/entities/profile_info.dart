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
