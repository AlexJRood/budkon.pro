import 'package:crm/invoices/form/models/revenue_expenses_form_state_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RevenueFormNotifier extends StateNotifier<RevenueExpensesFormState> {
  RevenueFormNotifier() : super(RevenueExpensesFormState.initial());

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  int _daysInMonth(int year, int month) {
    final firstNextMonth =
        (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final lastThisMonth = firstNextMonth.subtract(const Duration(days: 1));
    return lastThisMonth.day;
  }

  DateTime _addMonthsClamped(DateTime date, int monthsToAdd) {
    final total = (date.year * 12 + (date.month - 1)) + monthsToAdd;
    final newY = total ~/ 12;
    final newM = (total % 12) + 1;
    final maxDay = _daysInMonth(newY, newM);
    final newD = date.day > maxDay ? maxDay : date.day;
    return DateTime(newY, newM, newD);
  }

  DateTime _applyPreset(DateTime invoiceDate, InvoiceDuePreset preset) {
    switch (preset) {
      case InvoiceDuePreset.day1:
        return invoiceDate.add(const Duration(days: 1));
      case InvoiceDuePreset.day3:
        return invoiceDate.add(const Duration(days: 3));
      case InvoiceDuePreset.week1:
        return invoiceDate.add(const Duration(days: 7));
      case InvoiceDuePreset.week2:
        return invoiceDate.add(const Duration(days: 14));
      case InvoiceDuePreset.week3:
        return invoiceDate.add(const Duration(days: 21));
      case InvoiceDuePreset.month1:
        return _addMonthsClamped(invoiceDate, 1);
      case InvoiceDuePreset.month3:
        return _addMonthsClamped(invoiceDate, 3);
    }
  }

  InvoiceDuePreset? _presetFromDefaultDays(int days) {
    if (days == 1) return InvoiceDuePreset.day1;
    if (days == 3) return InvoiceDuePreset.day3;
    if (days == 7) return InvoiceDuePreset.week1;
    if (days == 14) return InvoiceDuePreset.week2;
    if (days == 21) return InvoiceDuePreset.week3;
    return null;
  }

  void focusDatePicker({required bool isPayment}) {
    state = state.copyWith(
      dateType: isPayment ? 'payment' : 'date',
      focusedDay: isPayment
          ? (state.selectedPaymentDate ?? DateTime.now())
          : (state.selectedDate ?? DateTime.now()),
    );
  }

  void setFocusedDay(DateTime day) {
    state = state.copyWith(focusedDay: day);
  }

  void ensureDefaults({required int defaultPaymentTermDays}) {
    final now = _dateOnly(DateTime.now());
    final invoice = state.selectedDate ?? now;
    final sale = state.selectedSaleDate ?? invoice;

    DateTime payment;
    if (state.selectedPaymentDate != null) {
      payment = state.selectedPaymentDate!;
    } else {
      payment = invoice.add(Duration(days: defaultPaymentTermDays));
    }

    if (payment.isBefore(invoice)) {
      payment = invoice;
    }

    state.dateController.text = _fmtDate(invoice);
    state.saleDateController.text = _fmtDate(sale);
    state.paymentDateController.text = _fmtDate(payment);

    state = state.copyWith(
      selectedDate: invoice,
      selectedSaleDate: sale,
      selectedPaymentDate: payment,
      focusedDay: invoice,
      duePreset: state.duePreset ?? _presetFromDefaultDays(defaultPaymentTermDays),
    );
  }

  void setInvoiceDate(DateTime date) {
    final d = _dateOnly(date);

    DateTime? nextPayment = state.selectedPaymentDate;

    if (state.duePreset != null) {
      nextPayment = _applyPreset(d, state.duePreset!);
    } else if (nextPayment != null && nextPayment.isBefore(d)) {
      nextPayment = d;
    }

    state.dateController.text = _fmtDate(d);
    if (nextPayment != null) {
      state.paymentDateController.text = _fmtDate(nextPayment);
    }

    state = state.copyWith(
      selectedDate: d,
      selectedPaymentDate: nextPayment,
      focusedDay: d,
    );
  }

  void setPaymentDate(DateTime date) {
    final d = _dateOnly(date);
    final invoice = state.selectedDate;
    final next = (invoice != null && d.isBefore(invoice)) ? invoice : d;

    state.paymentDateController.text = _fmtDate(next);

    state = state.copyWith(
      selectedPaymentDate: next,
      focusedDay: next,
      clearDuePreset: true,
    );
  }

  void setDuePreset(InvoiceDuePreset preset) {
    final invoice = state.selectedDate ?? _dateOnly(DateTime.now());
    final payment = _applyPreset(invoice, preset);

    state.dateController.text = _fmtDate(invoice);
    state.paymentDateController.text = _fmtDate(payment);

    state = state.copyWith(
      selectedDate: invoice,
      selectedPaymentDate: payment,
      focusedDay: invoice,
      duePreset: preset,
    );
  }

  void setPaid(bool value) {
    if (value && state.selectedPaymentDate == null) {
      final fallback = _dateOnly(
        state.selectedSaleDate ?? state.selectedDate ?? DateTime.now(),
      );
      state.paymentDateController.text = _fmtDate(fallback);
      state = state.copyWith(
        isPaid: true,
        selectedPaymentDate: fallback,
        focusedDay: fallback,
        clearDuePreset: true,
      );
      return;
    }

    state = state.copyWith(isPaid: value);
  }

  void setInvoiceType(String value) {
    state = state.copyWith(invoiceType: value);
  }

  void setSaleDate(DateTime date) {
    final d = _dateOnly(date);
    state.saleDateController.text = _fmtDate(d);
    state = state.copyWith(selectedSaleDate: d);
  }

  void selectCalendarDate(DateTime date, {required bool isPayment}) {
    if (isPayment) {
      setPaymentDate(date);
    } else {
      setInvoiceDate(date);
    }
  }

  void setClient(int clientId) {
    state = state.copyWith(clients: clientId);
  }

  void setObjectId(int objectId) {
    state = state.copyWith(objectId: objectId);
  }

  void clearTransaction() {
    state = state.copyWith(objectId: null);
  }

  void clearClient() {
    state = state.copyWith(clients: null);
  }


  void setClientInvoice(int? invoiceDataId) {
    state = state.copyWith(clientInvoice: invoiceDataId);
  }

  void setClientAndInvoice({
    required int? clientId,
    int? clientInvoiceId,
  }) {
    state = state.copyWith(
      clients: clientId,
      clientInvoice: clientInvoiceId,
    );
  }

  void setContractor(int? contractorId) {
    state = state.copyWith(contractor: contractorId);
  }

  void setInvoiceBuyer({
    int? clientId,
    int? clientInvoiceId,
    int? contractorId,
  }) {
    state = state.copyWith(
      clients: clientId,
      clientInvoice: clientInvoiceId,
      contractor: contractorId,
    );
  }

  void clearInvoiceBuyer() {
    state = state.copyWith(
      clients: null,
      clientInvoice: null,
      contractor: null,
    );
  }

  void setName(String value) {
    state.nameController.text = value;
    state = state.copyWith();
  }

  void setTransactionType(String value) {
    state.transactionTypeController.text = value;
    state = state.copyWith();
  }

  void setTotalAmountFromDouble(double value) {
    state.totalAmountController.text = value.toStringAsFixed(2);
    state = state.copyWith();
  }

  void setCurrency(String value) {
    state.currencyController.text = value;
    state = state.copyWith();
  }

  void clearForm({bool keepMyInvoiceData = true}) {
    final preservedMyInvoiceData = state.myInvoiceData;

    state.nameController.clear();
    state.transactionTypeController.clear();
    state.totalAmountController.clear();
    state.currencyController.text = 'PLN';
    state.taxAmountController.clear();
    state.dateController.clear();
    state.saleDateController.clear();
    state.noteController.clear();
    state.paymentDateController.clear();
    state.whenMonthlyPaymentOverController.clear();
    state.invoiceNumberController.clear();

    state = state.copyWith(
      statusId: 0,
      objectId: null,
      myInvoiceData: keepMyInvoiceData ? preservedMyInvoiceData : null,
      clients: null,
      clientInvoice: null,
      contractor: null,
      contentType: null,
      createdBy: null,
      paymentMethods: null,
      selectedDate: null,
      selectedPaymentDate: null,
      selectedSaleDate: null,
      isPaid: false,
      isMonthlyPayment: false,
      focusedDay: DateTime.now(),
      dateType: 'date',
      invoiceType: 'Invoice',
      clearDuePreset: true,
      invoiceNumberReservationId: null,
      invoiceNumberReservationExpiresAt: null,
    );
  }

  void setInvoiceNumberPreview({
    required String invoiceNumber,
    required String reservationId,
    required DateTime expiresAt,
  }) {
    state.invoiceNumberController.text = invoiceNumber;
    state = state.copyWith(
      invoiceNumberReservationId: reservationId,
      invoiceNumberReservationExpiresAt: expiresAt,
    );
  }

  void clearInvoiceNumberPreview() {
    state.invoiceNumberController.clear();
    state = state.copyWith(
      invoiceNumberReservationId: null,
      invoiceNumberReservationExpiresAt: null,
    );
  }

  bool get isInvoiceNumberReservationExpired =>
      state.isInvoiceNumberReservationExpired;

  void setPaymentMethod(String? value) {
    state = state.copyWith(paymentMethods: value);
  }
}

final revenueFormProvider =
    StateNotifierProvider<RevenueFormNotifier, RevenueExpensesFormState>(
  (ref) => RevenueFormNotifier(),
);

final selectedCurrencyProvider = StateProvider<String>((ref) => 'PLN');