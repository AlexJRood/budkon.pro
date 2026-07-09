import 'dart:typed_data';

import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:reports/reports/report_editor/model/report_template_model.dart';
import 'package:reports/reports/report_pdf_page/models/pdf_report_model.dart';

class PdfGeneratorService {
  // ── Fallback palette (used when no template) ──────────────────────────────
  static const _kPrimaryColor   = PdfColor.fromInt(0xFF171A1F);
  static const _kSecondaryColor = PdfColor.fromInt(0xFF667085);
  static const _kAccentColor    = PdfColor.fromInt(0xFF5FCDD9);
  static const _kCardColor      = PdfColor.fromInt(0xFFF6F7F9);
  static const _kPriceColor     = PdfColor.fromInt(0xFF101828);
  static const _kLightText      = PdfColor.fromInt(0xFF98A2B3);
  static const _kBorderColor    = PdfColor.fromInt(0xFFE7ECF2);

  // ── Runtime palette (set in generateReportPdf) ────────────────────────────
  late PdfColor _primary;
  late PdfColor _accent;
  late PdfColor _cardColor;
  late PdfColor _price;
  late PdfColor _secondary;
  late PdfColor _lightText;
  late PdfColor _border;

  String _formatMoney(num? amount, String? currency) {
    if (amount == null) return '-';
    final fmt = NumberFormat.currency(locale: 'pl_PL', symbol: '', decimalDigits: 2);
    final cur = (currency ?? '').trim().toLowerCase();
    final money = fmt.format(amount).trim();
    return cur.isEmpty ? money : '$money $cur';
  }

  static PdfColor _hexToPdf(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) {
      return PdfColor.fromInt(int.parse('FF$clean', radix: 16));
    }
    if (clean.length == 8) {
      return PdfColor.fromInt(int.parse(clean, radix: 16));
    }
    return _kAccentColor;
  }

  Future<Uint8List> generateReportPdf(
    PdfReportModel reportData, {
    ReportTemplateModel? template,
  }) async {
    // Apply palette from template or fall back to defaults
    _primary   = template != null ? _hexToPdf(template.colorText)       : _kPrimaryColor;
    _accent    = template != null ? _hexToPdf(template.colorPrimary)    : _kAccentColor;
    _cardColor = template != null ? _hexToPdf(template.colorBackground) : _kCardColor;
    _price     = _kPriceColor;
    _secondary = _kSecondaryColor;
    _lightText = _kLightText;
    _border    = _kBorderColor;

    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold    = await PdfGoogleFonts.robotoBold();
    final fontItalic  = await PdfGoogleFonts.robotoItalic();

    // Download logo if provided
    pw.ImageProvider? logoImage;
    final logoUrl = template?.logoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        logoImage = await networkImage(logoUrl);
      } catch (_) {
        logoImage = null;
      }
    }

    // Section visibility flags
    final tpl = template ?? const ReportTemplateModel();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 54),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
        ),
        header: (context) => _buildHeader(template, logoImage),
        footer: (context) => _buildFooter(context, template),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 16),
            _buildLocationSection(reportData),
            pw.SizedBox(height: 18),
            _buildEstimatedPrice(reportData),
            pw.SizedBox(height: 22),
            if (tpl.showPricesInArea && reportData.pricesInArea != null) ...[
              _buildPricesChart(reportData),
              pw.SizedBox(height: 18),
            ],
            if (tpl.showAccuracyIndex && reportData.accuracyIndex != null) ...[
              _buildAccuracyIndex(reportData),
              pw.SizedBox(height: 18),
            ],
            if (tpl.showRentalData && reportData.rentalData != null) ...[
              _buildRentalData(reportData),
              pw.SizedBox(height: 18),
            ],
            if (reportData.estimation != null) ...[
              _buildEstimationDetails(reportData),
              pw.SizedBox(height: 18),
            ],
            if (tpl.showGovernmentData && reportData.report?.governmentData != null) ...[
              _buildGovernmentSection(reportData),
              pw.SizedBox(height: 18),
            ],
            if (tpl.showComparables &&
                reportData.comparable != null &&
                reportData.comparable!.isNotEmpty)
              _buildComparables(reportData),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ── Header ────────────────────────────────────────────────────────────────

  pw.Widget _buildHeader(ReportTemplateModel? template, pw.ImageProvider? logo) {
    final companyName = template?.companyName.isNotEmpty == true
        ? template!.companyName
        : (template?.agentName.isNotEmpty == true ? template!.agentName : 'HOUSLY');

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo or company name on the left
          if (logo != null)
            pw.Image(logo, height: 36, fit: pw.BoxFit.contain)
          else
            pw.Text(
              companyName,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: _accent,
                letterSpacing: 1.5,
              ),
            ),
          // Report title on the right
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Property Report'.tr,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
              if (template?.agentName.isNotEmpty == true)
                pw.Text(
                  template!.agentName,
                  style: pw.TextStyle(fontSize: 9, color: _secondary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  pw.Widget _buildFooter(pw.Context context, ReportTemplateModel? template) {
    final parts = <String>[];
    if (template?.phone.isNotEmpty == true) parts.add(template!.phone);
    if (template?.email.isNotEmpty == true) parts.add(template!.email);
    if (template?.companyName.isNotEmpty == true) parts.add(template!.companyName);

    final footerText = template?.customFooter.isNotEmpty == true
        ? template!.customFooter
        : parts.join('  ·  ');

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              footerText,
              style: pw.TextStyle(fontSize: 8, color: _lightText),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _lightText),
          ),
        ],
      ),
    );
  }

  // ── Card container ────────────────────────────────────────────────────────

  pw.Widget _card(pw.Widget child) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: _border),
      ),
      child: child,
    );
  }

  // ── Location ──────────────────────────────────────────────────────────────

  pw.Widget _buildLocationSection(PdfReportModel reportData) {
    final location = reportData.location;
    final report   = reportData.report;

    final line2 = [
      report?.propertyType,
      report?.typeOfBuilding,
      report?.buildingMaterial,
    ].where((e) => e != null && e!.trim().isNotEmpty).join(' • ');

    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            location?.fullAddress ?? location?.address ?? report?.streetAddress ?? 'Address not available'.tr,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _primary),
          ),
          if (line2.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(line2, style: pw.TextStyle(fontSize: 12, color: _secondary)),
          ],
          pw.SizedBox(height: 14),
          pw.Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              if (report?.floorArea != null) _smallTag('${report!.floorArea!.toStringAsFixed(0)} m²'),
              if (report?.bedrooms != null)  _smallTag('${report!.bedrooms} rooms'),
              if (report?.bathrooms != null) _smallTag('${report!.bathrooms} bathrooms'),
              if (report?.floorLevel != null) _smallTag('floor ${report!.floorLevel}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _smallTag(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _cardColor,
        borderRadius: pw.BorderRadius.circular(100),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, color: _primary)),
    );
  }

  // ── Estimated price ───────────────────────────────────────────────────────

  pw.Widget _buildEstimatedPrice(PdfReportModel reportData) {
    final price    = reportData.report?.valueEstimate ?? reportData.estimation?.estimatedValue;
    final currency = reportData.report?.currency ?? reportData.estimation?.currency;

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            _formatMoney(price, currency),
            style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: _price),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Estimated selling price'.tr, style: pw.TextStyle(fontSize: 11, color: _secondary)),
        ],
      ),
    );
  }

  // ── Prices chart ──────────────────────────────────────────────────────────

  pw.Widget _buildPricesChart(PdfReportModel reportData) {
    final prices   = reportData.pricesInArea!;
    final min      = prices.minPrice ?? 0;
    final avg      = prices.averagePrice ?? 0;
    final max      = prices.maxPrice ?? 0;
    final currency = prices.currency;

    final values = [
      min,
      min + (avg - min) * 0.2,
      min + (avg - min) * 0.55,
      avg,
      avg + (max - avg) * 0.3,
      avg + (max - avg) * 0.65,
      max,
    ];

    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('prices_in_the_area'.tr, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primary)),
          if (prices.sampleSize != null) ...[
            pw.SizedBox(height: 4),
            pw.Text('${prices.sampleSize} ${'offers_in_sample'.tr}', style: pw.TextStyle(fontSize: 11, color: _secondary)),
          ],
          pw.SizedBox(height: 18),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: values.map((v) => _buildBar(v, max)).toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _priceSummary('min'.tr, _formatMoney(min, currency)),
              _priceSummary('avg'.tr, _formatMoney(avg, currency)),
              _priceSummary('max'.tr, _formatMoney(max, currency)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBar(double value, double maxValue) {
    final ratio = maxValue > 0 ? (value / maxValue).clamp(0.1, 1.0) : 0.1;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5),
      child: pw.Container(
        width: 24,
        height: 90 * ratio,
        decoration: pw.BoxDecoration(color: _accent, borderRadius: pw.BorderRadius.circular(8)),
      ),
    );
  }

  pw.Widget _priceSummary(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _primary)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _lightText)),
      ],
    );
  }

  // ── Accuracy index ────────────────────────────────────────────────────────

  pw.Widget _buildAccuracyIndex(PdfReportModel reportData) {
    final accuracy = reportData.accuracyIndex!;
    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('accuracy_index'.tr, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primary)),
          pw.SizedBox(height: 16),
          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metricPdf('confidence'.tr,          '${(accuracy.percentage ?? 0).toStringAsFixed(1)}%'),
              _metricPdf('comparable_offers'.tr,   '${accuracy.offersCount ?? 0}'),
              _metricPdf('estimated_error_range'.tr, accuracy.areaM2 != null ? '${accuracy.areaM2!.toStringAsFixed(1)} m²' : '-'),
              _metricPdf('median_area_delta'.tr,   accuracy.medianAreaDeltaPct != null ? '${(accuracy.medianAreaDeltaPct! * 100).toStringAsFixed(1)}%' : '-'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _metricPdf(String title, String value) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _cardColor,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 9, color: _secondary)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _primary)),
        ],
      ),
    );
  }

  // ── Rental data ───────────────────────────────────────────────────────────

  pw.Widget _buildRentalData(PdfReportModel reportData) {
    final rental = reportData.rentalData!;
    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('rental_information'.tr, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primary)),
          pw.SizedBox(height: 14),
          _buildDataRow('monthly_rental'.tr,          _formatMoney(rental.rental,               rental.currency)),
          _buildDataRow('administrative_fees'.tr,     _formatMoney(rental.administrativeFees,   rental.currency)),
          _buildDataRow('estimated_annual_rental'.tr, _formatMoney(rental.estimatedRentalPrice, rental.currency)),
        ],
      ),
    );
  }

  // ── Estimation details ────────────────────────────────────────────────────

  pw.Widget _buildEstimationDetails(PdfReportModel reportData) {
    final estimation = reportData.estimation!;
    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('valuation_details'.tr, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primary)),
          pw.SizedBox(height: 14),
          _buildDataRow('estimated_value'.tr,    _formatMoney(estimation.estimatedValue,     estimation.currency)),
          _buildDataRow('price_per_m2'.tr,       _formatMoney(estimation.estimatedPricePerM2, estimation.currency)),
          _buildDataRow('low_estimate'.tr,       _formatMoney(estimation.lowValue,           estimation.currency)),
          _buildDataRow('high_estimate'.tr,      _formatMoney(estimation.highValue,          estimation.currency)),
          _buildDataRow('confidence_percent'.tr, '${((estimation.confidence ?? 0) * 100).toStringAsFixed(1)}%'),
          _buildDataRow('comparables_used'.tr,   '${estimation.comparablesUsed ?? 0}'),
        ],
      ),
    );
  }

  // ── Government section ────────────────────────────────────────────────────

  pw.Widget _buildGovernmentSection(PdfReportModel reportData) {
    final gov = reportData.report?.governmentData;
    if (gov == null) return pw.SizedBox.shrink();

    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('environment_public_data'.tr, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primary)),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _smallTag('${'weather'.tr}: ${gov.weatherCount}'),
              _smallTag('${'hydrology'.tr}: ${gov.hydrologicalCount}'),
              _smallTag('${'schools_smog'.tr}: ${gov.schoolsCount}'),
              _smallTag('${'hospitals'.tr}: ${gov.hospitalsCount}'),
              _smallTag('${'air_quality'.tr}: ${gov.airQualityData != null ? "OK" : "-"}'),
              _smallTag('${'bdot10k'.tr}: ${gov.bdot10kWms != null ? "OK" : "-"}'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Comparables ───────────────────────────────────────────────────────────

  pw.Widget _buildComparables(PdfReportModel reportData) {
    final items = reportData.comparable!.take(8).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('comparable_properties'.tr, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primary)),
        pw.SizedBox(height: 14),
        ...items.map((comp) {
          final address = comp.fullAddress.isNotEmpty ? comp.fullAddress : 'address_not_available'.tr;

          final box = pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: _border),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(comp.title ?? 'comparable_property'.tr,
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _primary)),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(_formatMoney(comp.price, comp.currency),
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _price)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Text(address, style: pw.TextStyle(fontSize: 10, color: _secondary)),
                pw.SizedBox(height: 10),
                pw.Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (comp.floorArea != null)   _smallTag('${comp.floorArea!.toStringAsFixed(0)} m²'),
                    if (comp.rooms != null)        _smallTag('${comp.rooms} ${'roms'.tr}'),
                    if (comp.bathrooms != null)    _smallTag('${comp.bathrooms} ${'bathrooms'.tr}'),
                    if (comp.pricePerM2 != null)   _smallTag(_formatMoney(comp.pricePerM2, comp.currency)),
                    if (comp.similarityScore != null) _smallTag('${'Score'.tr}: ${comp.similarityScore!.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          );

          if (comp.link != null && comp.link!.isNotEmpty) {
            return pw.UrlLink(destination: comp.link!, child: box);
          }
          return box;
        }),
      ],
    );
  }

  // ── Data row ──────────────────────────────────────────────────────────────

  pw.Widget _buildDataRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: pw.Text(label, style: pw.TextStyle(fontSize: 12, color: _secondary))),
          pw.SizedBox(width: 10),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _primary)),
        ],
      ),
    );
  }
}

// Extension used in section-visibility checks
extension _TemplateVisibility on ReportTemplateModel {
  bool get showPricesInArea => true; // no dedicated field, always show
}
