import 'package:crm/invoices/form/provider/invoice_table_provider.dart';

/// Checks if row has meaningful input.
/// Comments in English.
bool isMeaningfulInvoiceRow(InvoiceRow r) {
  final nameOk = r.productName.trim().isNotEmpty;
  final qtyOk = r.quantity.isFinite && r.quantity > 0;

  // If you want to allow zero-priced items, change this to true.
  final hasAnyPrice = (r.unitPrice.isFinite && r.unitPrice > 0) ||
      (r.unitDiscount.isFinite && r.unitDiscount > 0);

  return nameOk && qtyOk && hasAnyPrice;
}

/// Builds STRICT backend INPUT payload for invoice items.
/// IMPORTANT: Do NOT send line_* amounts, backend computes them.
/// Comments in English.
Map<String, dynamic> buildInvoiceItemsInputPayload(List<InvoiceRow> rows) {
  final cleaned = rows.where(isMeaningfulInvoiceRow).toList();

  return {
    "items": cleaned.map((r) {
      return {
        "preset_uuid": r.presetUuid,
        "product_name": r.productName.trim(),
        "advance": r.advance,
        "quantity": r.quantity,
        "unit": r.iu.trim(),
        "gtu": r.gtu.trim().isEmpty ? "OTHER" : r.gtu.trim(),
        "unit_net_price": r.unitPrice,
        // NOTE: Your model uses unitDiscount as LINE discount (not per unit).
        // Keep backend consistent with that.
        "unit_discount": r.unitDiscount,
        "vat_rate": r.vatRate,
        "currency": (r.currency.trim().isEmpty) ? "PLN" : r.currency.trim(),
      };
    }).toList(),
  };
}

/// Builds payload and forces ONE currency across all rows.
/// This avoids "mixed currency" bugs in totals.
/// Comments in English.
Map<String, dynamic> buildInvoiceItemsInputPayloadStrictCurrency(
  List<InvoiceRow> rows, {
  required String expectedCurrency,
}) {
  final cur = expectedCurrency.trim().isEmpty ? 'PLN' : expectedCurrency.trim();

  // Force currency on every row (immutable copy).
  final normalized = rows.map((r) => r.copyWith(currency: cur)).toList();

  return buildInvoiceItemsInputPayload(normalized);
}
