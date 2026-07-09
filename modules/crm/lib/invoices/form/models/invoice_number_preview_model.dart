class InvoiceNumberPreview {
  final String invoiceNumber;
  final String reservationId;
  final DateTime expiresAt;

  const InvoiceNumberPreview({
    required this.invoiceNumber,
    required this.reservationId,
    required this.expiresAt,
  });

  factory InvoiceNumberPreview.fromJson(Map<String, dynamic> json) {
    return InvoiceNumberPreview(
      invoiceNumber: (json['invoice_number'] ?? '').toString(),
      reservationId: (json['reservation_id'] ?? '').toString(),
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
