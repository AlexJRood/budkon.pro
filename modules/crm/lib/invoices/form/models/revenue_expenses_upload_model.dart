class RevenueExpensesUploadModel {
  final int? statusId;
  final String? name;
  final String? transactionType;

  /// Legacy: keep (you currently use it as GROSS).
  final String totalAmount;

  /// NEW: send both net and gross to backend for correct storage.
  final String? totalNetAmount;
  final String? totalGrossAmount;

  final String currency;
  final String? taxAmount;

  /// date = issue date
  final String? date;

  /// NEW: sale date (data sprzedaży)
  final String? saleDate;

  final String? note;
  final String? paymentDate;
  final String? paymentMethods;
  final bool isPaid;
  final bool isMonthlyPayment;
  final String? whenMonthlyPaymentIsOver;

  /// Optional: keep for UI/debug, backend can ignore if reservation_id is provided.
  final String? invoiceNumber;

  /// Reservation id from preview endpoint
  /// Backend expects: invoice_number_reservation_id
  final String? invoiceNumberReservationId;

  final Map<String, dynamic>? invoiceData;
  final Map<String, dynamic>? invoiceItem;
  final List<dynamic>? documents;
  final List<dynamic>? tags;
  final String? status;
  final int? objectId;
  final int? myInvoiceData;
  final int? clients;
  final int? clientInvoice;
  final int? contractor;
  final int contentType;
  final int? createdBy;

  RevenueExpensesUploadModel({
    this.statusId,
    this.name,
    this.transactionType,
    required this.totalAmount,
    this.totalNetAmount,
    this.totalGrossAmount,
    this.currency = 'PLN',
    this.taxAmount,
    this.date,
    this.saleDate,
    this.note,
    this.paymentDate,
    this.paymentMethods,
    this.isPaid = false,
    this.isMonthlyPayment = false,
    this.whenMonthlyPaymentIsOver,
    this.invoiceNumber,
    this.invoiceNumberReservationId,
    this.invoiceData,
    this.invoiceItem,
    this.documents,
    this.tags,
    this.status,
    this.objectId,
    this.myInvoiceData,
    this.clients,
    this.clientInvoice,
    this.contractor,
    this.contentType = 43,
    this.createdBy,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'status_id': statusId,
      'name': name,
      'transaction_type': transactionType,

      // Legacy
      'total_amount': totalAmount,

      // NEW: store correct totals on server
      'total_net_amount': totalNetAmount,
      'total_gross_amount': totalGrossAmount,

      'currency': currency,
      'tax_amount': taxAmount,

      // Dates
      'date': date,
      'sale_date': saleDate,
      'payment_date': paymentDate,

      'note': note,
      'payment_methods': paymentMethods,
      'is_paid': isPaid,
      'is_monthly_payment': isMonthlyPayment,
      'when_monthly_payment_is_over': whenMonthlyPaymentIsOver,

      // Keep sending invoice_number if you want, but reservation_id should be source of truth.
      'invoice_number': invoiceNumber,

      // IMPORTANT: must match backend field
      'invoice_number_reservation_id': invoiceNumberReservationId,

      'invoice_data': invoiceData,
      'invoice_item': invoiceItem,
      'documents': documents,
      'tags': tags,
      'status': status,
      'object_id': objectId,
      'my_invoice_data': myInvoiceData,
      'clients': clients,
      'client_invoice': clientInvoice,
      'contractor': contractor,
      'content_type': contentType,
      'created_by': createdBy,
    };

    // Optional cleanup: remove nulls to keep payload small and DRF-friendly.
    data.removeWhere((key, value) => value == null);

    return data;
  }
}
