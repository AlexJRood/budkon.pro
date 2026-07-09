// lib/crm_agent/crm/widgets/invoice_pdf.dart

import 'dart:typed_data';

import 'package:crm/invoices/models/templates.dart';
import 'package:crm/shared/models/expense/crm_expenses_download_model.dart';
import 'package:crm/shared/models/revenue_model.dart';
import 'package:flutter/material.dart' show Color;
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:core/theme/apptheme.dart';

class InvoicePdf {
  static Future<Uint8List> build({
    required ThemeColors theme,
    required Object data,
    bool isMobile = false, // zachowane dla spójności API
    InvoiceTemplateModel? template,
  }) async {
    final revenue = data is AgentRevenueModel ? data : null;
    final expense = data is CrmExpensesDownloadModel ? data : null;

    final invoiceNumber =
        revenue?.invoiceNumber ?? expense?.invoiceNumber ?? '';
    final amount = (revenue?.amount ?? expense?.amount ?? '0').toString();
    final currency = (revenue?.currency ?? expense?.currency ?? '').toString();
    final DateTime? issueDate = revenue?.dateCreate ?? expense?.dateCreate;
    final DateTime? dueDate = revenue?.paymentDate ?? expense?.paymentDate;

    // ================= TEMPLATE CONFIG =================

    // sections_config z JSON-a
    final cfg = template?.sectionsConfig ?? <String, dynamic>{};

    // widoczność i kolejność sekcji
    final List<Map<String, dynamic>> sections =
        [
          ...(cfg['sections'] as List? ?? const []),
        ].whereType<Map<String, dynamic>>().toList();

    bool sectionVisible(String id) {
      final s = sections.firstWhere(
        (m) => m['id'] == id,
        orElse: () => const {},
      );
      if (s.isEmpty) return true; // domyślnie pokazujemy
      final v = s['visible'];
      if (v == null) return true;
      return v == true;
    }

    final showHeader = sectionVisible('header');
    final showParties = sectionVisible('parties');
    final showItems = sectionVisible('items');
    final showPayments = sectionVisible('payments');
    final showFooter = sectionVisible('footer');

    // kolumny tabeli pozycji
    final List<String> columns =
        [
          ...(cfg['columns'] as List? ??
              const [
                'name',
                'quantity',
                'unit_net_price',
                'vat',
                'line_gross_amount',
              ]),
        ].map((e) => e.toString()).toList();

    // spacing między sekcjami
    final double sectionSpacing =
        (cfg['section_spacing'] as num?)?.toDouble() ?? 12.0;

    // payment options
    final bool showPaymentTerms = (cfg['show_payment_terms'] as bool?) ?? true;
    final bool showBankAccount = (cfg['show_bank_account'] as bool?) ?? true;

    final String paymentTermsLabel =
        template?.paymentTermsLabel.trim().isNotEmpty == true
            ? template!.paymentTermsLabel
            : 'payment_terms'.tr;

    final String footerText = template?.footerText.trim() ?? '';

    // marginesy z templatu (mm -> pt)
    final double marginTopMm = (template?.marginTop ?? 15).toDouble();
    final double marginBottomMm = (template?.marginBottom ?? 15).toDouble();
    final double marginLeftMm = (template?.marginLeft ?? 10).toDouble();
    final double marginRightMm = (template?.marginRight ?? 10).toDouble();

    final pageFormat = _resolvePageFormat(template);
    final doc = pw.Document();

    // font – na razie helvetica
    final pdfTheme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

    // ================= KOLORY Z TEMPLATE =================

    Color colorFromHex(String? hex, Color fallback) {
      if (hex == null || hex.isEmpty) return fallback;
      var value = hex.replaceAll('#', '');
      if (value.length == 6) value = 'FF$value';
      try {
        return Color(int.parse(value, radix: 16));
      } catch (_) {
        return fallback;
      }
    }

    final Color baseTextColor = colorFromHex(
      template?.primaryColor,
      theme.textColor,
    );
    final Color secondaryTextColor = colorFromHex(
      template?.secondaryColor,
      theme.textColor.withAlpha(178),
    );
    final Color accentBgColor = colorFromHex(
      template?.accentColor,
      theme.textFieldColor.withAlpha(13),
    );

    final pdfTextColor = _pdf(baseTextColor);
    final pdfSecondaryTextColor = _pdf(secondaryTextColor);
    final pdfBorderColor = _pdf(theme.themeColor);
    final pdfAccentBg = _pdf(accentBgColor);

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.only(
          top: marginTopMm * PdfPageFormat.mm,
          bottom: marginBottomMm * PdfPageFormat.mm,
          left: marginLeftMm * PdfPageFormat.mm,
          right: marginRightMm * PdfPageFormat.mm,
        ),
        theme: pdfTheme,
        build: (context) {
          final children = <pw.Widget>[];

          void addSection(pw.Widget child) {
            if (children.isNotEmpty) {
              children.add(pw.SizedBox(height: sectionSpacing));
            }
            children.add(child);
          }

          // HEADER
          if (showHeader) {
            addSection(
              _buildHeaderSection(
                invoiceNumber: invoiceNumber,
                issueDate: issueDate,
                dueDate: dueDate,
                pdfTextColor: pdfTextColor,
                pdfSecondaryColor: pdfSecondaryTextColor,
                pdfBorderColor: pdfBorderColor,
                template: template,
              ),
            );
          }

          // PARTIES (Seller / Buyer)
          if (showParties) {
            addSection(
              _buildPartiesSection(
                pdfBorderColor: pdfBorderColor,
                pdfTextColor: pdfTextColor,
              ),
            );
          }

          // ITEMS TABLE
          if (showItems) {
            addSection(
              _buildItemsTableSection(
                columns: columns,
                amount: amount,
                currency: currency,
                pdfBorderColor: pdfBorderColor,
                pdfTextColor: pdfTextColor,
                pdfSecondaryTextColor: pdfSecondaryTextColor,
                pdfAccentBg: pdfAccentBg,
              ),
            );
          }

          // PAYMENTS SECTION
          if (showPayments && (showPaymentTerms || showBankAccount)) {
            addSection(
              _buildPaymentsSection(
                showPaymentTerms: showPaymentTerms,
                showBankAccount: showBankAccount,
                paymentTermsLabel: paymentTermsLabel,
                pdfTextColor: pdfTextColor,
                pdfSecondaryTextColor: pdfSecondaryTextColor,
              ),
            );
          }

          // FOOTER
          if (showFooter && footerText.isNotEmpty) {
            addSection(
              pw.Text(
                footerText,
                style: pw.TextStyle(color: pdfSecondaryTextColor, fontSize: 9),
              ),
            );
          }

          // Stopka "Generated on..."
          children.add(pw.Spacer());
          children.add(
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                '${'generated_on'.tr} ${_formatDate(DateTime.now())}',
                style: pw.TextStyle(
                  color: _withOpacity(pdfSecondaryTextColor, .8),
                  fontSize: 8,
                ),
              ),
            ),
          );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          );
        },
      ),
    );

    return doc.save();
  }

  // =========================================================
  // ==  SECTION HELPERS  ====================================
  // =========================================================

  static pw.Widget _buildHeaderSection({
    required String invoiceNumber,
    required DateTime? issueDate,
    required DateTime? dueDate,
    required PdfColor pdfTextColor,
    required PdfColor pdfSecondaryColor,
    required PdfColor pdfBorderColor,
    required InvoiceTemplateModel? template,
  }) {
    final titleStyle = pw.TextStyle(
      color: pdfTextColor,
      fontWeight: pw.FontWeight.bold,
      fontSize: 18,
    );
    final labelStyle = pw.TextStyle(
      color: _withOpacity(pdfSecondaryColor, .8),
      fontSize: 10,
    );
    final valueStyle = pw.TextStyle(
      color: pdfTextColor,
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    );

    // header: INVOICE + nr + daty
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('invoice_header'.tr, style: titleStyle),
                pw.SizedBox(height: 4),
                pw.Text(
                  invoiceNumber.isEmpty ? '#' : '#$invoiceNumber',
                  style: pw.TextStyle(color: pdfSecondaryColor, fontSize: 11),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '${'issue_date_label'.tr} ${_formatDate(issueDate)}',
                  style: labelStyle,
                ),
                pw.Text('${'due_date_label'.tr} ${_formatDate(dueDate)}', style: labelStyle),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: pdfBorderColor),
      ],
    );
  }

  static pw.Widget _buildPartiesSection({
    required PdfColor pdfBorderColor,
    required PdfColor pdfTextColor,
  }) {
    pw.Widget card(String title, List<String> lines) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(
            color: _withOpacity(pdfBorderColor, .4),
            width: 0.7,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: pdfTextColor,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            ...lines.map(
              (line) => pw.Text(
                line,
                style: pw.TextStyle(color: pdfTextColor, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: card('seller_label'.tr, const [
            'Company name',
            'Street 1',
            '00-000 City',
            'NIP: 123-456-78-90',
          ]),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: card('buyer_label'.tr, const [
            'Company name',
            'Street 1',
            '00-000 City',
            'NIP: 123-456-78-90',
          ]),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTableSection({
    required List<String> columns,
    required String amount,
    required String currency,
    required PdfColor pdfBorderColor,
    required PdfColor pdfTextColor,
    required PdfColor pdfSecondaryTextColor,
    required PdfColor pdfAccentBg,
  }) {
    int flexFor(String key) {
      switch (key) {
        case 'name':
          return 4;
        case 'quantity':
          return 1;
        case 'unit_net_price':
          return 2;
        case 'vat':
          return 1;
        case 'line_gross_amount':
          return 2;
        default:
          return 1;
      }
    }

    String labelFor(String key) {
      switch (key) {
        case 'name':
          return 'item_column'.tr;
        case 'quantity':
          return 'qty_column'.tr;
        case 'unit_net_price':
          return 'net_price_column'.tr;
        case 'vat':
          return 'vat_column'.tr;
        case 'line_gross_amount':
          return 'gross_column'.tr;
        default:
          return key;
      }
    }

    final headerStyle = pw.TextStyle(
      color: pdfTextColor,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final cellStyle = pw.TextStyle(color: pdfTextColor, fontSize: 10);

    // przykładowe wiersze – dokładnie jak w preview
    final sampleRows = [
      {
        'name': 'Service A',
        'quantity': '1',
        'unit_net_price': '1 000.00',
        'vat': '23%',
        'line_gross_amount': '1 230.00',
      },
      {
        'name': 'Service B',
        'quantity': '2',
        'unit_net_price': '500.00',
        'vat': '23%',
        'line_gross_amount': '1 230.00',
      },
    ];

    final totalGross = '2 460.00';

    // szerokości kolumn
    final Map<int, pw.TableColumnWidth> colWidths = {};
    for (int i = 0; i < columns.length; i++) {
      final key = columns[i];
      colWidths[i] = pw.FlexColumnWidth(flexFor(key).toDouble());
    }

    pw.Widget headerCell(String key) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(labelFor(key), style: headerStyle),
      );
    }

    pw.Widget bodyCell(String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Text(value, style: cellStyle),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: _withOpacity(pdfBorderColor, .3),
        width: 0.7,
      ),
      columnWidths: colWidths,
      children: [
        // header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: pdfAccentBg),
          children: [for (final key in columns) headerCell(key)],
        ),
        // rows
        ...sampleRows.map(
          (row) => pw.TableRow(
            children: [for (final key in columns) bodyCell(row[key] ?? '')],
          ),
        ),
        // total
        pw.TableRow(
          children: [
            for (int i = 0; i < columns.length; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child:
                    (i == 0)
                        ? pw.Text(
                          'total_label'.tr,
                          style: pw.TextStyle(
                            color: pdfTextColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        )
                        : (i == columns.length - 1)
                        ? pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            '$amount $currency',
                            style: pw.TextStyle(
                              color: pdfTextColor,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        )
                        : pw.SizedBox(),
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPaymentsSection({
    required bool showPaymentTerms,
    required bool showBankAccount,
    required String paymentTermsLabel,
    required PdfColor pdfTextColor,
    required PdfColor pdfSecondaryTextColor,
  }) {
    pw.Widget box(String title, String content) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(
            color: _withOpacity(pdfSecondaryTextColor, .4),
            width: 0.7,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: pdfTextColor,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              content,
              style: pw.TextStyle(color: pdfSecondaryTextColor, fontSize: 9),
            ),
          ],
        ),
      );
    }

    final children = <pw.Widget>[];

    if (showPaymentTerms) {
      children.add(
        pw.Expanded(
          child: box(
            paymentTermsLabel.isEmpty ? 'payment_terms'.tr : paymentTermsLabel,
            'payment_terms_description'.tr,
          ),
        ),
      );
    }

    if (showPaymentTerms && showBankAccount) {
      children.add(pw.SizedBox(width: 12));
    }

    if (showBankAccount) {
      children.add(
        pw.Expanded(
          child: box(
            'bank_account_label'.tr,
            'Bank: Hously Bank S.A.\n'
                'IBAN: PL00 0000 0000 0000 0000 0000 0000\n'
                'SWIFT: HOUXPLPW',
          ),
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  // =========================================================
  // ==  COMMON HELPERS  =====================================
  // =========================================================

  static String _formatDate(DateTime? d) =>
      (d == null) ? '' : DateFormat('yyyy-MM-dd').format(d);

  static PdfPageFormat _resolvePageFormat(InvoiceTemplateModel? template) {
    final size = template?.paperSize.toUpperCase() ?? 'A4';
    final orientation = template?.orientation ?? 'portrait';

    PdfPageFormat base;
    switch (size) {
      case 'LETTER':
        base = PdfPageFormat.letter;
        break;
      default:
        base = PdfPageFormat.a4;
    }
    if (orientation == 'landscape') {
      return base.landscape;
    }
    return base;
  }

  static PdfColor _pdf(Color c) => PdfColor.fromInt(c.value);

  static PdfColor _withOpacity(PdfColor c, double o) => PdfColor.fromInt(
    ((o * 255).round() << 24) |
        (((c.red * 255).round() & 0xFF) << 16) |
        (((c.green * 255).round() & 0xFF) << 8) |
        ((c.blue * 255).round() & 0xFF),
  );
}
