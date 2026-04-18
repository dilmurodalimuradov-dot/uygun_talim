class Certificate {
  const Certificate({
    required this.id,
    required this.title,
    required this.issuedAt,
    required this.fileUrl,
  });

  final String id;
  final String title;
  final String issuedAt;
  final String fileUrl;
}
