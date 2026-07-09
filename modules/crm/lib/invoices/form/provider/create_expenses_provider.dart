import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crm/crm_urls.dart';
import 'package:crm/invoices/form/models/revenue_expenses_upload_model.dart';
import 'package:crm/invoices/form/provider/form_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/user/user/user_provider.dart';

import 'invoice_table_provider.dart';

class CreateExpensesNotifier extends StateNotifier<AsyncValue<void>> {
  CreateExpensesNotifier() : super(const AsyncValue.data(null));

  Future<void> createExpense(WidgetRef ref) async {
    state = const AsyncValue.loading();

    final form = ref.read(revenueFormProvider);

    final rows = ref.read(invoiceTableProvider);
    final notifier = ref.read(invoiceTableProvider.notifier);

    // ✅ RevenueExpensesUploadModel.invoiceItem expects Map<String, dynamic>?
    // so wrap the list into a map payload.
    final Map<String, dynamic> invoiceItemsPayload =
        rows.toInvoiceItemsPayload(key: 'items'); // change key if backend expects different

    final totalAmount = notifier.totalVatAmount.toStringAsFixed(2);

    final userAsync = await ref.read(userProvider.future);
    final int? userId = int.tryParse(userAsync?.userId ?? '');

    final model = RevenueExpensesUploadModel(
      statusId: form.statusId,
      name: form.nameController.text,
      transactionType: 'Expense',
      totalAmount: totalAmount,
      currency: form.currencyController.text,
      taxAmount: '200',
      date: form.dateController.text,
      note: form.noteController.text,
      paymentDate: form.paymentDateController.text,
      isPaid: form.isPaid,
      isMonthlyPayment: form.isMonthlyPayment,
      whenMonthlyPaymentIsOver: form.whenMonthlyPaymentOverController.text.isNotEmpty
          ? form.whenMonthlyPaymentOverController.text
          : null,
      invoiceNumber: form.invoiceNumberController.text,
      myInvoiceData: form.myInvoiceData,
      clients: form.clients,
      clientInvoice: form.clientInvoice,
      contractor: form.contractor,
      contentType: 43,
      createdBy: userId,

      // ✅ FIX HERE:
      invoiceItem: invoiceItemsPayload,

      paymentMethods: form.paymentMethods,
      objectId: form.objectId,
    );

    final modelJson = model.toJson();

    try {
      final response = await ApiServices.post(
        CrmUrls.addFinanceAppExpenses,
        data: modelJson,
        hasToken: true,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        state = const AsyncValue.data(null);
        // ignore: avoid_print
        debugPrint('✅ Expense created');
      } else {
        final errorBody = jsonEncode(response?.data);
        // ignore: avoid_print
        debugPrint('❌ API Validation Errors:\n$errorBody');
        state = AsyncValue.error(
          '${'expense_creation_failed'.tr}: ${response?.statusCode}',
          StackTrace.empty,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // ignore: avoid_print
      debugPrint('❌ Exception: $e');
    }
  }
}

final createExpensesProvider =
    StateNotifierProvider<CreateExpensesNotifier, AsyncValue<void>>(
  (ref) => CreateExpensesNotifier(),
);
