import 'package:crm/invoices/form/provider/form_provider.dart';
import 'package:crm/invoices/form/provider/invoice_buyer_provider.dart';
import 'package:crm/invoices/form/provider/invoice_table_provider.dart';
import 'invoice_payload_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Totals computed from invoice table.
/// Backend should still compute totals, but UI needs them for preview.
/// Comments in English.
class InvoiceTotals {
  final double net;
  final double vat;
  final double gross;

  const InvoiceTotals({
    required this.net,
    required this.vat,
    required this.gross,
  });
}

/// Provider computing totals from table rows.
/// Comments in English.
final invoiceTotalsProvider = Provider<InvoiceTotals>((ref) {
  final rows = ref.watch(invoiceTableProvider);

  double net = 0;
  double vat = 0;
  double gross = 0;

  for (final row in rows) {
    if (isMeaningfulInvoiceRow(row)) {
      net += row.netAmount;
      vat += row.vatAmount;
      gross += row.grossValue;
    }
  }

  return InvoiceTotals(
    net: net,
    vat: vat,
    gross: gross,
  );
});

/// Builds FINAL create/update payload for Revenue Invoice.
/// - Items come ONLY from table.
/// - Do NOT send line_*
/// - Do NOT send total_amount/tax_amount (backend computes)
/// - Buyer data is sent as buyer_mode + buyer_invoice_data.
/// Comments in English.
Map<String, dynamic> buildRevenueInvoiceCreatePayload({
  required WidgetRef ref,
}) {
  final form = ref.read(revenueFormProvider);
  final rows = ref.read(invoiceTableProvider);
  final currency = ref.read(selectedCurrencyProvider);
  final buyer = ref.read(invoiceBuyerProvider);

  final meaningfulRows = rows.where(isMeaningfulInvoiceRow).toList();

  final itemsPayload = buildInvoiceItemsInputPayloadStrictCurrency(
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
    'date': issueDate,
    'issue_date': issueDate,
    'sale_date': saleDate,
    'payment_date': paymentDate,
    'payment_due_date': paymentDate,
    'payment_methods': form.paymentMethods,
    'is_paid': form.isPaid,
    'invoice_number': form.invoiceNumberController.text.trim().isNotEmpty
        ? form.invoiceNumberController.text.trim()
        : null,
    'invoice_number_reservation_id': form.invoiceNumberReservationId,
    'transaction_id': form.objectId?.toString(),
    'items': itemsPayload['items'],
    'buyer_mode': buyer.mode.backendValue,
  };

  if (buyer.mode == InvoiceBuyerMode.existingContact) {
    payload['client_id'] = form.clients ?? buyer.clientId;
    payload['client_invoice'] = form.clientInvoice ?? buyer.clientInvoiceId;

    final buyerData = buyer.toBuyerInvoiceDataPayload();
    if (buyerData.isNotEmpty) {
      payload['buyer_invoice_data'] = buyerData;
    }
  }

  if (buyer.mode == InvoiceBuyerMode.newContactFromGus) {
    payload['buyer_invoice_data'] = buyer.toBuyerInvoiceDataPayload();
    payload['create_contact_from_buyer'] = true;
  }

  if (buyer.mode == InvoiceBuyerMode.oneTime) {
    payload['buyer_invoice_data'] = buyer.toBuyerInvoiceDataPayload();
  }

  payload.removeWhere((_, value) {
    if (value == null) return true;
    if (value is String && value.trim().isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    return false;
  });

  return payload;
}

/// Wire totals into form preview (no loops).
/// Place this inside your page/widget build in a safe place.
/// Example usage:
///   wireInvoiceTotalsToForm(ref);
/// Comments in English.
void wireInvoiceTotalsToForm(WidgetRef ref) {
  ref.listen<InvoiceTotals>(invoiceTotalsProvider, (prev, next) {
    final notifier = ref.read(revenueFormProvider.notifier);

    notifier.setTotalAmountFromDouble(next.gross);
    notifier.state.taxAmountController.text = next.vat.toStringAsFixed(2);
  });
}