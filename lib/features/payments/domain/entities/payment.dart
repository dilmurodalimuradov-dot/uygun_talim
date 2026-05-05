class Payment {
  const Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.courseTitle = '',
    this.courseImage = '',
    this.paidAt = '',
  });

  final String id;
  final String amount;
  final String currency;
  final String status;
  final String createdAt;
  final String courseTitle;
  final String courseImage;
  final String paidAt;

  bool get isSuccess {
    final s = status.toLowerCase().trim();
    return s == 'success' ||
        s == 'completed' ||
        s == 'paid' ||
        s == 'successful' ||
        s == 'approved' ||
        s == 'confirmed' ||
        s == '2';
  }
}
