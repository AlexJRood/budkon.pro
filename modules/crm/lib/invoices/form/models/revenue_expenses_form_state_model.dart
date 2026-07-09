import 'package:flutter/material.dart';

enum InvoiceDuePreset {
  day1,
  day3,
  week1,
  week2,
  week3,
  month1,
  month3,
}

class RevenueExpensesFormState {
  static const Object _unset = Object();

  // Controllers
  final TextEditingController nameController;
  final TextEditingController transactionTypeController;
  final TextEditingController totalAmountController;
  final TextEditingController currencyController;
  final TextEditingController taxAmountController;

  /// Invoice issue date
  final TextEditingController dateController;

  /// Sale date
  final TextEditingController saleDateController;

  final TextEditingController noteController;

  /// Payment date
  final TextEditingController paymentDateController;

  final TextEditingController whenMonthlyPaymentOverController;
  final TextEditingController invoiceNumberController;

  /// Invoice number reservation
  final String? invoiceNumberReservationId;
  final DateTime? invoiceNumberReservationExpiresAt;

  // Flags
  final bool isPaid;
  final bool isMonthlyPayment;

  // Relations / ids
  final int statusId;
  final int? objectId;
  final int? myInvoiceData;
  final int? clients;
  final int? clientInvoice;
  final int? contractor;
  final int? contentType;
  final int? createdBy;

  final String? paymentMethods;

  // Dates
  final DateTime? selectedDate;
  final DateTime? selectedPaymentDate;
  final DateTime? selectedSaleDate;

  final DateTime focusedDay;
  final String dateType;

  // Invoice type + due preset
  final String invoiceType; // 'Invoice' | 'Proforma'
  final InvoiceDuePreset? duePreset;

  RevenueExpensesFormState({
    required this.nameController,
    required this.transactionTypeController,
    required this.totalAmountController,
    required this.currencyController,
    required this.taxAmountController,
    required this.dateController,
    required this.saleDateController,
    required this.noteController,
    required this.paymentDateController,
    required this.whenMonthlyPaymentOverController,
    required this.invoiceNumberController,
    required this.invoiceNumberReservationId,
    required this.invoiceNumberReservationExpiresAt,
    this.isPaid = false,
    this.isMonthlyPayment = false,
    this.statusId = 0,
    this.objectId,
    this.myInvoiceData,
    this.clients,
    this.clientInvoice,
    this.contractor,
    this.contentType,
    this.createdBy,
    this.paymentMethods,
    this.selectedDate,
    this.selectedPaymentDate,
    this.selectedSaleDate,
    DateTime? focusedDay,
    this.dateType = 'date',
    this.invoiceType = 'Invoice',
    this.duePreset,
  }) : focusedDay = focusedDay ?? DateTime.now();

  factory RevenueExpensesFormState.initial() => RevenueExpensesFormState(
        nameController: TextEditingController(),
        transactionTypeController: TextEditingController(),
        totalAmountController: TextEditingController(),
        currencyController: TextEditingController(text: 'PLN'),
        taxAmountController: TextEditingController(),
        dateController: TextEditingController(),
        saleDateController: TextEditingController(),
        noteController: TextEditingController(),
        paymentDateController: TextEditingController(),
        whenMonthlyPaymentOverController: TextEditingController(),
        invoiceNumberController: TextEditingController(),
        invoiceNumberReservationId: null,
        invoiceNumberReservationExpiresAt: null,
      );

  bool get isInvoiceNumberReservationExpired {
    final exp = invoiceNumberReservationExpiresAt;
    if (exp == null) return true;
    return DateTime.now().isAfter(exp);
  }

  RevenueExpensesFormState copyWith({
    bool? isPaid,
    bool? isMonthlyPayment,
    int? statusId,

    Object? objectId = _unset,
    Object? myInvoiceData = _unset,
    Object? clients = _unset,
    Object? clientInvoice = _unset,
    Object? contractor = _unset,
    Object? contentType = _unset,
    Object? createdBy = _unset,
    Object? paymentMethods = _unset,

    Object? selectedDate = _unset,
    Object? selectedPaymentDate = _unset,
    Object? selectedSaleDate = _unset,

    DateTime? focusedDay,
    String? dateType,
    String? invoiceType,
    InvoiceDuePreset? duePreset,

    Object? invoiceNumberReservationId = _unset,
    Object? invoiceNumberReservationExpiresAt = _unset,

    bool clearDuePreset = false,
  }) {
    return RevenueExpensesFormState(
      nameController: nameController,
      transactionTypeController: transactionTypeController,
      totalAmountController: totalAmountController,
      currencyController: currencyController,
      taxAmountController: taxAmountController,
      dateController: dateController,
      saleDateController: saleDateController,
      noteController: noteController,
      paymentDateController: paymentDateController,
      whenMonthlyPaymentOverController: whenMonthlyPaymentOverController,
      invoiceNumberController: invoiceNumberController,
      invoiceNumberReservationId: identical(invoiceNumberReservationId, _unset)
          ? this.invoiceNumberReservationId
          : invoiceNumberReservationId as String?,
      invoiceNumberReservationExpiresAt:
          identical(invoiceNumberReservationExpiresAt, _unset)
              ? this.invoiceNumberReservationExpiresAt
              : invoiceNumberReservationExpiresAt as DateTime?,
      isPaid: isPaid ?? this.isPaid,
      isMonthlyPayment: isMonthlyPayment ?? this.isMonthlyPayment,
      statusId: statusId ?? this.statusId,
      objectId: identical(objectId, _unset) ? this.objectId : objectId as int?,
      myInvoiceData: identical(myInvoiceData, _unset)
          ? this.myInvoiceData
          : myInvoiceData as int?,
      clients: identical(clients, _unset) ? this.clients : clients as int?,
      clientInvoice: identical(clientInvoice, _unset)
          ? this.clientInvoice
          : clientInvoice as int?,
      contractor: identical(contractor, _unset)
          ? this.contractor
          : contractor as int?,
      contentType: identical(contentType, _unset)
          ? this.contentType
          : contentType as int?,
      createdBy: identical(createdBy, _unset)
          ? this.createdBy
          : createdBy as int?,
      paymentMethods: identical(paymentMethods, _unset)
          ? this.paymentMethods
          : paymentMethods as String?,
      selectedDate: identical(selectedDate, _unset)
          ? this.selectedDate
          : selectedDate as DateTime?,
      selectedPaymentDate: identical(selectedPaymentDate, _unset)
          ? this.selectedPaymentDate
          : selectedPaymentDate as DateTime?,
      selectedSaleDate: identical(selectedSaleDate, _unset)
          ? this.selectedSaleDate
          : selectedSaleDate as DateTime?,
      focusedDay: focusedDay ?? this.focusedDay,
      dateType: dateType ?? this.dateType,
      invoiceType: invoiceType ?? this.invoiceType,
      duePreset: clearDuePreset ? null : (duePreset ?? this.duePreset),
    );
  }
}