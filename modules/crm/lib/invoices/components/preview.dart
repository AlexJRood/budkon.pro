// lib/invoices/template_generator/preview.dart
// Live preview of the invoice using current template config.

import 'package:crm/invoices/providers/template_generator.dart';
import 'package:crm/utils/color_parser.dart';
import 'package:crm/widget/section_resolved_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';

/// Tryb pracy podglądu:
/// - sample  -> edytor templatki (stałe dane przykładowe)
/// - runtime -> realne dane faktury (revenue/expense/transaction)
enum InvoicePreviewMode { sample, runtime }

/// Dane jednej strony (sprzedawca/kupujący) do runtime podglądu.
class InvoicePartyData {
  final String title; // np. "Seller", "Buyer"
  final String name;
  final List<String> addressLines;
  final String? email;
  final String? phone;

  const InvoicePartyData({
    required this.title,
    required this.name,
    this.addressLines = const [],
    this.email,
    this.phone,
  });
}

/// Dane jednej pozycji na fakturze.
class InvoiceItemData {
  final String name;
  final num quantity;
  final String unitNetPriceLabel; // już z walutą, np. "1 000.00 PLN"
  final String vatLabel; // np. "23%"
  final String lineGrossLabel; // np. "1 230.00 PLN"

  const InvoiceItemData({
    required this.name,
    this.quantity = 1,
    required this.unitNetPriceLabel,
    required this.vatLabel,
    required this.lineGrossLabel,
  });
}

/// Runtime dane faktury przekazywane do canvasu przy realnym użyciu.
class InvoiceRuntimeData {
  final String invoiceNumber;
  final String projectLabel; // co pokazujemy w headerze jako "Project"
  final String totalGrossLabel; // tekst w linii "Total" (z walutą)
  final DateTime? issueDate;
  final DateTime? dueDate;

  final InvoicePartyData? seller;
  final InvoicePartyData? buyer;

  final List<InvoiceItemData> items;

  const InvoiceRuntimeData({
    required this.invoiceNumber,
    required this.projectLabel,
    required this.totalGrossLabel,
    this.issueDate,
    this.dueDate,
    this.seller,
    this.buyer,
    this.items = const [],
  });

  /// Prosta próbka dla trybu sample – używana w edytorze,
  /// gdybyś kiedyś chciał tam też pokazać runtime.
  factory InvoiceRuntimeData.sample() {
    return const InvoiceRuntimeData(
      invoiceNumber: 'FV/2025/001',
      projectLabel: 'Sample project 2 460.00 PLN',
      totalGrossLabel: '2 460.00 PLN',
      items: [
        InvoiceItemData(
          name: 'Service A',
          quantity: 1,
          unitNetPriceLabel: '1 000.00 PLN',
          vatLabel: '23%',
          lineGrossLabel: '1 230.00 PLN',
        ),
        InvoiceItemData(
          name: 'Service B',
          quantity: 2,
          unitNetPriceLabel: '500.00 PLN',
          vatLabel: '23%',
          lineGrossLabel: '1 230.00 PLN',
        ),
      ],
    );
  }
}

/// STARA klasa: używana tylko w edytorze – jest nakładką:
/// - nagłówek „Live preview”
/// - przycisk „Pobierz przykładową fakturę”
/// - środek: InvoiceTemplateCanvas w trybie `sample`.
class InvoiceTemplateLivePreview extends StatelessWidget {
  final InvoiceTemplateFormState form;
  final ThemeColors theme;
  final InvoiceTemplateFormNotifier notifier;
  final VoidCallback onDownloadSample;

  const InvoiceTemplateLivePreview({
    super.key,
    required this.form,
    required this.theme,
    required this.notifier,
    required this.onDownloadSample,
  });

  double get _aspectRatio {
    // A4: 210x297 => ~0.707; Letter can be treated similarly.
    const a4Portrait = 0.707;
    final isPortrait = form.orientation == 'portrait';
    final base = a4Portrait;
    return isPortrait ? base : 1 / base;
  }

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'live_preview_title'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onDownloadSample,
              icon: const Icon(Icons.download),
              label: Text('download_sample_invoice'.tr),
              style: TextButton.styleFrom(foregroundColor: theme.themeColor),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          'sample_invoice_preview_description'.tr,
          style: TextStyle(
            color: theme.textColor.withAlpha(178),
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 12.h),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: form.marginTop.toDouble(),
                    bottom: form.marginBottom.toDouble(),
                    left: form.marginLeft.toDouble(),
                    right: form.marginRight.toDouble(),
                  ),
                  // TU: nowy canvas, tryb SAMPLE, dane przykładowe
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: InvoiceTemplateCanvas(
                      form: form,
                      theme: theme,
                      mode: InvoicePreviewMode.sample,
                      runtimeData: InvoiceRuntimeData.sample(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// NOWY „silnik” – ten sam będzie użyty:
/// - w edytorze (sample)
/// - w runtime (realne dane)
/// - dalej może być zre-użyty w PDF (przepisany na pdf-widgets).
class InvoiceTemplateCanvas extends StatelessWidget {
  final InvoiceTemplateFormState form;
  final ThemeColors theme;
  final InvoicePreviewMode mode;
  final InvoiceRuntimeData? runtimeData;

  const InvoiceTemplateCanvas({
    super.key,
    required this.form,
    required this.theme,
    this.mode = InvoicePreviewMode.sample,
    this.runtimeData,
  });
  @override
  Widget build(BuildContext context) {
    final primary = form.primaryColor.toColor(
      fallback: const Color(0xFFF2F2F2),
    ); // section bg
    final secondary = form.secondaryColor.toColor(
      fallback: const Color(0xFFDDDDDD),
    ); // borders
    final accent = form.accentColor.toColor(
      fallback: const Color(0xFF111111),
    ); // text

    final visibleSections = form.sections
        .where((s) => s.visible)
        .toList(growable: false);

    if (visibleSections.isEmpty) {
      return Center(
        child: Text(
          'no_sections_enabled'.tr,
          style: TextStyle(color: theme.textColor, fontSize: 10.sp),
        ),
      );
    }

    final children = <Widget>[];

    for (int i = 0; i < visibleSections.length; i++) {
      final section = visibleSections[i];

      if (i > 0) {
        children.add(SizedBox(height: form.sectionSpacing.h));
      }

      final resolved = resolveSectionStyle(
        section,
        globalBg: primary,
        globalText: accent,
        globalBorder: secondary,
        globalSectionSpacing: form.sectionSpacing,
      );
      final bool shouldWrap =
          section.useCustomBranding ||
          section.paddingVertical != null ||
          section.hasBorder == false;
      final Color sectionPrimary =
          section.useCustomBranding ? resolved.bg : primary;
      final Color sectionText =
          section.useCustomBranding ? resolved.text : accent;

      final body = _buildSectionBody(
        section: section,
        primary: sectionPrimary,
        secondary: secondary,
        accent: sectionText,
        theme: theme,
      );

      children.add(
        shouldWrap
            ? wrapSection(
              child: body,

              paddingV: resolved.paddingV,
              hasBorder: resolved.hasBorder,
            )
            : body,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // ---------------- GŁÓWNY „switch” sekcji ----------------

  Widget _buildSectionBody({
    required InvoiceSectionConfig section,
    required Color primary,
    required Color secondary,
    required Color accent,
    required ThemeColors theme,
  }) {
    switch (section.id) {
      case 'header':
        return _buildHeader(primary, secondary, accent, theme);

      case 'parties':
        return _buildParties(primary, secondary, accent);

      case 'items':
        return _buildItemsTable(primary, secondary, accent);

      case 'payments':
        if (!form.showPaymentTerms && !form.showBankAccount) {
          return Text(
            'payment_section_disabled'.tr,
            style: TextStyle(
              color: accent.withAlpha(180),
              fontSize: 10.sp,
            ).copyWith(fontStyle: FontStyle.italic),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (form.showPaymentTerms)
              Expanded(
                flex: 2,
                child: _infoBlock(
                  title: form.paymentTermsLabel,
                  content:
                      'payment_terms_description'.tr,
                  primary: primary,
                  secondary: secondary,
                  accent: accent,
                ),
              ),
            if (form.showPaymentTerms && form.showBankAccount)
              SizedBox(width: 8.w),
            if (form.showBankAccount)
              Expanded(
                flex: 2,
                child: _infoBlock(
                  title: 'bank_account_label'.tr,
                  content:
                      'Bank: Hously Bank S.A.\nIBAN: PL00 0000 0000 0000 0000 0000 0000\nSWIFT: HOUXPLPW',
                  primary: primary,
                  secondary: secondary,
                  accent: accent,
                ),
              ),
          ],
        );

      case 'footer':
        if (form.footerText.isEmpty) {
          return Text(
            'footer_notes_empty'.tr,
            style: TextStyle(
              color: accent,
              fontSize: 10.sp,
            ).copyWith(fontStyle: FontStyle.italic),
          );
        }
        return Text(
          form.footerText,
          style: TextStyle(color: accent, fontSize: 9.sp),
        );

      default:
        // Custom section MVP – tekst z customText lub label.
        return Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: secondary),
          ),
          child: Text(
            section.customText ?? section.label,
            style: TextStyle(color: accent, fontSize: 11.sp),
          ),
        );
    }
  }

  // ---------------- HEADER ----------------

  Widget _buildHeader(
    Color primary,
    Color secondary,
    Color accent,
    ThemeColors theme,
  ) {
    final logoWidget =
        form.showLogo
            ? Container(
              width: 60.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: secondary),
              ),
              alignment: Alignment.center,
              child: Text(
                'logo_placeholder'.tr,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.sp,
                ),
              ),
            )
            : const SizedBox.shrink();

    // SAMPLE vs RUNTIME:
    final runtime = runtimeData;
    final invoiceNo =
        (mode == InvoicePreviewMode.runtime && runtime != null)
            ? (runtime.invoiceNumber.isEmpty ? '—' : runtime.invoiceNumber)
            : 'FV/2025/001';

    final projectLabel =
        (mode == InvoicePreviewMode.runtime && runtime != null)
            ? runtime.projectLabel
            : 'Sample project 2 460.00 PLN';

    final issueDateLabel =
        (mode == InvoicePreviewMode.runtime && runtime != null)
            ? _formatDate(runtime.issueDate)
            : '2025-01-01';

    final dueDateLabel =
        (mode == InvoicePreviewMode.runtime && runtime != null)
            ? _formatDate(runtime.dueDate)
            : '2025-01-14';

    final titleAndScope = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'invoice_header'.tr,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w800,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '${'template_prefix'.tr} ${form.name.isEmpty ? 'unnamed_template'.tr : form.name}',
          style: TextStyle(color: accent, fontSize: 10.sp),
        ),
        SizedBox(height: 2.h),
        Text(
          '${'scope_prefix'.tr} ${form.scope}',
          style: TextStyle(color: accent, fontSize: 10.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          '${'project_prefix'.tr} $projectLabel',
          style: TextStyle(color: accent, fontSize: 11.sp),
        ),
      ],
    );

    final datesColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${'number_prefix'.tr} $invoiceNo',
          style: TextStyle(color: accent, fontSize: 11.sp),
        ),
        SizedBox(height: 2.h),
        Text(
          '${'issue_date_prefix'.tr} $issueDateLabel',
          style: TextStyle(color: accent, fontSize: 10.sp),
        ),
        Text(
          '${'due_date_prefix'.tr} $dueDateLabel',
          style: TextStyle(color: accent, fontSize: 10.sp),
        ),
      ],
    );

    switch (form.logoPosition) {
      case 'right':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleAndScope),
            SizedBox(width: 12.w),
            datesColumn,
            if (form.showLogo) ...[SizedBox(width: 12.w), logoWidget],
          ],
        );

      case 'center':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (form.showLogo)
              Align(alignment: Alignment.center, child: logoWidget),
            if (form.showLogo) SizedBox(height: 6.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: titleAndScope), datesColumn],
            ),
          ],
        );

      case 'left':
      default:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (form.showLogo) logoWidget,
            if (form.showLogo) SizedBox(width: 12.w),
            Expanded(child: titleAndScope),
            datesColumn,
          ],
        );
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    // yyyy-MM-dd
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // ---------------- PARTIES ----------------

  Widget _buildParties(Color primary, Color secondary, Color accent) {
    // SAMPLE dane:
    final sampleSeller = InvoicePartyData(
      title: 'seller_label'.tr,
      name: 'Hously Sp. z o.o.',
      addressLines: [
        'ul. Przykładowa 1',
        '70-001 Szczecin',
        'NIP: 123-456-78-90',
      ],
    );

    final sampleBuyer = InvoicePartyData(
      title: 'buyer_label'.tr,
      name: 'Best Client S.A.',
      addressLines: ['ul. Klienta 10', '00-100 Warszawa', 'NIP: 987-654-32-10'],
    );

    final runtimeSeller =
        (mode == InvoicePreviewMode.runtime && runtimeData != null)
            ? runtimeData!.seller
            : null;

    final runtimeBuyer =
        (mode == InvoicePreviewMode.runtime && runtimeData != null)
            ? runtimeData!.buyer
            : null;

    final seller = runtimeSeller ?? sampleSeller;
    final buyer = runtimeBuyer ?? sampleBuyer;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _infoCard(
            title: seller.title,
            lines: [
              seller.name,
              ...seller.addressLines,
              if (seller.email != null && seller.email!.isNotEmpty)
                'E-mail: ${seller.email}',
              if (seller.phone != null && seller.phone!.isNotEmpty)
                'Phone: ${seller.phone}',
            ],
            labelStyle: TextStyle(color: accent, fontSize: 10.sp),
            valueStyle: TextStyle(
              color: accent.withAlpha(180),
              fontSize: 11.sp,
            ),
            primary: primary,
            secondary: secondary,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _infoCard(
            title: buyer.title,
            lines: [
              buyer.name,
              ...buyer.addressLines,
              if (buyer.email != null && buyer.email!.isNotEmpty)
                'E-mail: ${buyer.email}',
              if (buyer.phone != null && buyer.phone!.isNotEmpty)
                'Phone: ${buyer.phone}',
            ],
            labelStyle: TextStyle(color: accent, fontSize: 10.sp),
            valueStyle: TextStyle(
              color: accent.withAlpha(180),
              fontSize: 11.sp,
            ),
            primary: primary,
            secondary: secondary,
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String title,
    required List<String> lines,
    required TextStyle labelStyle,
    required TextStyle valueStyle,
    required Color primary,
    required Color secondary,
  }) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: labelStyle.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: 4.h),
          ...lines.map((line) => Text(line, style: valueStyle)),
        ],
      ),
    );
  }

  // ---------------- ITEMS TABLE ----------------
  Widget _buildItemsTable(Color primary, Color secondary, Color accent) {
    final columns = form.columns;

    TextStyle headerStyle = TextStyle(
      color: accent,
      fontSize: 10.sp,
      fontWeight: FontWeight.w700,
    );

    TextStyle cellStyle = TextStyle(color: accent, fontSize: 10.sp);

    Widget buildHeaderCell(
      String label, {
      int flex = 1,
      TextAlign align = TextAlign.left,
    }) {
      return Expanded(
        flex: flex,
        child: Text(label, style: headerStyle, textAlign: align),
      );
    }

    Widget buildCell(
      String value, {
      int flex = 1,
      TextAlign align = TextAlign.left,
    }) {
      return Expanded(
        flex: flex,
        child: Text(value, style: cellStyle, textAlign: align),
      );
    }

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

    TextAlign alignFor(String key) {
      switch (key) {
        case 'name':
          return TextAlign.left;
        default:
          return TextAlign.right;
      }
    }

    // SAMPLE rows:
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
    const sampleTotal = '2 460.00 PLN';

    // ✅ RUNTIME items come from runtimeData.items
    final List<InvoiceItemData> runtimeItems =
        (mode == InvoicePreviewMode.runtime && runtimeData != null)
            ? runtimeData!.items
            : const <InvoiceItemData>[];

    final bool useRuntimeItems =
        mode == InvoicePreviewMode.runtime && runtimeItems.isNotEmpty;

    final totalLabel =
        (useRuntimeItems && runtimeData != null)
            ? runtimeData!.totalGrossLabel
            : sampleTotal;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        color: primary,
        border: Border.all(color: secondary),
      ),

      child: Column(
        children: [
          // header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: primary.withAlpha(220),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6.r),
                topRight: Radius.circular(6.r),
              ),
            ),
            child: Row(
              children: [
                for (final key in columns)
                  buildHeaderCell(
                    labelFor(key),
                    flex: flexFor(key),
                    align: alignFor(key),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: secondary),

          // rows
          if (useRuntimeItems)
            ...runtimeItems.map(
              (row) => Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Row(
                  children: [
                    for (final key in columns)
                      buildCell(
                        _runtimeValueForKey(row, key),
                        flex: flexFor(key),
                        align: alignFor(key),
                      ),
                  ],
                ),
              ),
            )
          else
            ...sampleRows.map(
              (row) => Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Row(
                  children: [
                    for (final key in columns)
                      buildCell(
                        row[key] ?? '',
                        flex: flexFor(key),
                        align: alignFor(key),
                      ),
                  ],
                ),
              ),
            ),

          Divider(height: 1, color: secondary),

          // totals line
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            child: Row(
              children: [
                Expanded(
                  flex: columns.fold<int>(
                    0,
                    (prev, key) => prev + (key == 'name' ? flexFor(key) : 0),
                  ),
                  child: Text(
                    '${'total_label'.tr}:',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
                Expanded(
                  flex: columns.fold<int>(
                    0,
                    (prev, key) => prev + (key != 'name' ? flexFor(key) : 0),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      totalLabel,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _runtimeValueForKey(InvoiceItemData row, String key) {
    switch (key) {
      case 'name':
        return row.name;
      case 'quantity':
        return row.quantity.toString();
      case 'unit_net_price':
        return row.unitNetPriceLabel;
      case 'vat':
        return row.vatLabel;
      case 'line_gross_amount':
        return row.lineGrossLabel;
      default:
        return '';
    }
  }

  Widget _infoBlock({
    required String title,
    required String content,
    required Color primary,
    required Color secondary,
    required Color accent,
  }) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? 'info_label'.tr : title,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            content,
            style: TextStyle(color: accent.withAlpha(180), fontSize: 9.sp),
          ),
        ],
      ),
    );
  }
}

// TODO(v2.0): Add "issued via Hously" watermark for non-premium users.
// This block should only be rendered when:
// - template / company is on FREE or BASIC plan
// - NOT rendered for premium / white-label customers.
//
// Widget _buildHouslyWatermark() {
//   return Align(
//     alignment: Alignment.bottomRight,
//     child: Padding(
//       padding: const EdgeInsets.only(top: 12.0),
//       child: Text(
//         'Issued via superbee.cloud',
//         style: TextStyle(
//           color: Colors.grey.withAlpha(153),
//           fontSize: 8,
//           fontStyle: FontStyle.italic,
//         ),
//       ),
//     ),
//   );
// }
