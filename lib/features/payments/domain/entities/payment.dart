class Payment {
  const Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String amount;
  final String currency;
  final String status;
  final String createdAt;

  bool get isSuccess =>
      status.toLowerCase() == 'success' ||
      status.toLowerCase() == 'completed' ||
      status.toLowerCase() == 'paid';
}
