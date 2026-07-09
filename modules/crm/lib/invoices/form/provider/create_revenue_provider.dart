import 'dart:convert';

import 'package:crm/invoices/providers/invoice_payload_builder.dart';
import 'package:crm/invoices/form/provider/form_provider.dart';
import 'package:crm/invoices/form/provider/invoice_buyer_provider.dart';
import 'package:crm/invoices/form/provider/invoice_number_provider.dart';
import 'package:crm/invoices/form/provider/invoice_table_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';

final createRevenueProvider =
    StateNotifierProvider<CreateRevenueNotifier, AsyncValue<void>>(
  (ref) => CreateRevenueNotifier(),
);

class CreateRevenueNotifier extends StateNotifier<AsyncValue<void>> {
  CreateRevenueNotifier() : super(const AsyncValue.data(null));

  String _endpoint(String path) {
    final base = URLs.baseUrl.endsWith('/')
        ? URLs.baseUrl.substring(0, URLs.baseUrl.length - 1)
        : URLs.baseUrl;

    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$base$cleanPath';
  }

  String _safeError(dynamic data) {
    final text = data?.toString() ?? '';

    // Avoid rendering huge Django HTML debug pages in SnackBar.
    if (text.contains('<!DOCTYPE html') || text.contains('<html')) {
      return 'Server returned HTML error page. Check backend logs.';
    }

    try {
      return jsonEncode(data);
    } catch (_) {
      return text;
    }
  }

  void _validateBuyer(InvoiceBuyerDraft buyer) {
    if (buyer.mode == InvoiceBuyerMode.oneTime && !buyer.hasBuyerData) {
      throw Exception('buyer_data_required'.tr);
    }

    if (buyer.mode == InvoiceBuyerMode.newContactFromGus &&
        !buyer.hasBuyerData) {
      throw Exception('buyer_data_required'.tr);
    }
  }

  Map<String, dynamic> _buyerPayload({
    required InvoiceBuyerDraft buyer,
    required int? clientId,
    required int? clientInvoiceId,
  }) {
    final payload = <String, dynamic>{
      'buyer_mode': buyer.mode.backendValue,
    };

    if (buyer.mode == InvoiceBuyerMode.existingContact) {
      payload['client_id'] = clientId ?? buyer.clientId;
      payload['client_invoice'] = clientInvoiceId ?? buyer.clientInvoiceId;

      final buyerData = buyer.toBuyerInvoiceDataPayload();
      if (buyerData.isNotEmpty) {
        payload['buyer_invoice_data'] = buyerData;
      }

      return payload;
    }

    if (buyer.mode == InvoiceBuyerMode.newContactFromGus) {
      payload['buyer_invoice_data'] = buyer.toBuyerInvoiceDataPayload();
      payload['create_contact_from_buyer'] = true;
      return payload;
    }

    if (buyer.mode == InvoiceBuyerMode.oneTime) {
      payload['buyer_invoice_data'] = buyer.toBuyerInvoiceDataPayload();
      return payload;
    }

    return payload;
  }

  Future<void> createRevenue(WidgetRef ref) async {
    state = const AsyncValue.loading();

    try {
      final form = ref.read(revenueFormProvider);
      final buyer = ref.read(invoiceBuyerProvider);
      final rows = ref.read(invoiceTableProvider);
      final tableNotifier = ref.read(invoiceTableProvider.notifier);

      final meaningfulRows =
          rows.where(isMeaningfulInvoiceRow).toList(growable: false);

      if (meaningfulRows.isEmpty) {
        throw Exception('add_at_least_one_valid_invoice_item'.tr);
      }

      _validateBuyer(buyer);

      final currency = form.currencyController.text.trim().isNotEmpty
          ? form.currencyController.text.trim()
          : ref.read(selectedCurrencyProvider);

      tableNotifier.setCurrencyForAll(currency);

      final invoiceNumberNotifier = ref.read(invoiceNumberProvider.notifier);
      await invoiceNumberNotifier.ensureValidReservation();

      final reservationId = (form.invoiceNumberReservationId ?? '').trim();

      if (reservationId.isEmpty) {
        throw Exception('no_active_invoice_number_reservation'.tr);
      }

      final invoiceItemsPayload = buildInvoiceItemsInputPayloadStrictCurrency(
        meaningfulRows,
        expectedCurrency: currency,
      );

      final issueDate = form.dateController.text.trim();
      final saleDate = form.saleDateController.text.trim().isNotEmpty
          ? form.saleDateController.text.trim()
          : issueDate;
      final paymentDate = form.paymentDateController.text.trim();

      final payload = <String, dynamic>{
        'name': form.nameController.text.trim().isNotEmpty
            ? form.nameController.text.trim()
            : 'Faktura',
        'transaction_type': form.transactionTypeController.text.trim().isNotEmpty
            ? form.transactionTypeController.text.trim()
            : 'Income',
        'currency': currency,
        'date': issueDate.isNotEmpty ? issueDate : null,
        'issue_date': issueDate.isNotEmpty ? issueDate : null,
        'sale_date': saleDate.isNotEmpty ? saleDate : null,
        'payment_date': paymentDate.isNotEmpty ? paymentDate : null,
        'payment_due_date': paymentDate.isNotEmpty ? paymentDate : null,
        'payment_methods': form.paymentMethods,
        'is_paid': form.isPaid,
        'invoice_number': form.invoiceNumberController.text.trim().isNotEmpty
            ? form.invoiceNumberController.text.trim()
            : null,
        'invoice_number_reservation_id': reservationId,
        'transaction_id': form.objectId?.toString(),
        'items': invoiceItemsPayload['items'],
        ..._buyerPayload(
          buyer: buyer,
          clientId: form.clients,
          clientInvoiceId: form.clientInvoice,
        ),
      };

      payload.removeWhere((_, value) {
        if (value == null) return true;
        if (value is String && value.trim().isEmpty) return true;
        if (value is List && value.isEmpty) return true;
        if (value is Map && value.isEmpty) return true;
        return false;
      });

      final response = await ApiServices.post(
        _endpoint('/finance/revenues/create-invoice/'),
        data: payload,
        hasToken: true,
      );

      if (response != null &&
          response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        ref.read(invoiceNumberProvider.notifier).clear();
        state = const AsyncValue.data(null);
        return;
      }

      throw Exception(
        '${'revenue_creation_failed'.tr}: '
        '${response?.statusCode} ${_safeError(response?.data)}',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}