import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crm/invoices/components/preview.dart'; // InvoiceItemData, InvoiceRuntimeData
import 'package:crm/invoices/form/provider/invoice_table_provider.dart'; // InvoiceRow

// ===================================================
// Money formatting (same style as preview formatter)
// ===================================================
String _fmtMoney(num v, {required String currency}) {
  final fixed = v.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts.length > 1 ? parts[1] : '00';

  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    final idxFromEnd = intPart.length - i;
    buf.write(intPart[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(' ');
  }
  return '${buf.toString()}.$decPart $currency';
}

String _fmtQty(num q) {
  if (q % 1 == 0) return q.toInt().toString();
  return q.toString();
}

// ===================================================
// Rows -> Preview items
// ===================================================
List<InvoiceItemData> mapRowsToPreviewItems(
  List<InvoiceRow> rows,
  String fallbackCurrency,
) {
  final safeCurrency = fallbackCurrency.trim().isEmpty ? 'PLN' : fallbackCurrency.trim();

  return rows
      // optional: skip empty placeholder rows
      .where((r) =>
          r.productName.trim().isNotEmpty ||
          r.unitPrice != 0.0 ||
          r.unitDiscount != 0.0)
      .map((r) {
    final currency = r.currency.trim().isNotEmpty ? r.currency.trim() : safeCurrency;

    final netUnit = r.unitPrice;          // unit net price
    final vat = r.vatRate;                // percent
    final grossLine = r.grossValue;       // line gross (already computed in row)

    return InvoiceItemData(
      name: r.productName.trim().isEmpty ? '—' : r.productName.trim(),
      quantity: r.quantity,
      unitNetPriceLabel: _fmtMoney(netUnit, currency: currency),
      vatLabel: '${vat.toStringAsFixed(0)}%',
      lineGrossLabel: _fmtMoney(grossLine, currency: currency),
    );
  }).toList(growable: false);
}

// ===================================================
// Rows -> RuntimeData (items + totals)
// Use this when you want preview to reflect provider,
// not backend JSON.
// ===================================================
InvoiceRuntimeData runtimeFromInvoiceRows({
  required List<InvoiceRow> rows,
  required String invoiceNumber,
  required String projectLabel,
  required DateTime? issueDate,
  required DateTime? dueDate,
  required String fallbackCurrency,
}) {
  final safeCurrency = fallbackCurrency.trim().isEmpty ? 'PLN' : fallbackCurrency.trim();

  final items = mapRowsToPreviewItems(rows, safeCurrency);

  // Total gross from rows (source of truth)
  final totalGross = rows.fold<double>(0.0, (sum, r) => sum + r.grossValue);
  final totalLabel = _fmtMoney(totalGross, currency: safeCurrency);

  // If no items (all placeholder) -> still show 1 row so UI doesn't look broken
  final safeItems = items.isNotEmpty
      ? items
      : [
          InvoiceItemData(
            name: projectLabel.isEmpty ? 'Service' : projectLabel,
            quantity: 1,
            unitNetPriceLabel: totalLabel,
            vatLabel: '',
            lineGrossLabel: totalLabel,
          )
        ];

  return InvoiceRuntimeData(
    invoiceNumber: invoiceNumber.isEmpty ? '—' : invoiceNumber,
    projectLabel: projectLabel.isEmpty ? '—' : projectLabel,
    totalGrossLabel: totalLabel,
    issueDate: issueDate,
    dueDate: dueDate,
    items: safeItems,
  );
}

// ===================================================
// Optional helper provider: runtimeData from invoiceTableProvider
// (You can watch this in UI and pass directly to InvoiceTemplateCanvas)
// ===================================================
final invoiceRuntimeFromRowsProvider = Provider.family<InvoiceRuntimeData, _RuntimeArgs>((ref, args) {
  final rows = ref.watch(invoiceTableProvider);

  return runtimeFromInvoiceRows(
    rows: rows,
    invoiceNumber: args.invoiceNumber,
    projectLabel: args.projectLabel,
    issueDate: args.issueDate,
    dueDate: args.dueDate,
    fallbackCurrency: args.currency,
  );
});

@immutable
class _RuntimeArgs {
  final String invoiceNumber;
  final String projectLabel;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String currency;

  const _RuntimeArgs({
    required this.invoiceNumber,
    required this.projectLabel,
    required this.issueDate,
    required this.dueDate,
    required this.currency,
  });
}
