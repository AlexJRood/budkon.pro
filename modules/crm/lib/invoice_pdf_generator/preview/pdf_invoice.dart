import 'package:crm/invoice_pdf_generator/model/invoise_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:get/get_utils/get_utils.dart';


import 'package:printing/printing.dart'; // For printing and sharing the PDF

import 'dart:typed_data';

import 'package:int_to_words/int_to_words.dart';

void generateInvoicePdf(Invoice invoice, Uint8List logoBytes, DateTime issuie,
    DateTime due, String termsandconditions) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  height: 80,
                  width: 80,
                  child: pw.Image(
                    pw.MemoryImage(logoBytes),
                  ),
                ),
                // Invoice Info
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "${'invoice_number_prefix'.tr} ${invoice.invoiceNumber}".tr,
                      style: const pw.TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                        style: const pw.TextStyle(
                          fontSize: 10,
                        ),
                        "${'issue_date_label'.tr} ${issuie.toLocal()}".tr),
                    pw.Text(
                      "${'sale_date_label'.tr} ${due.toLocal()}".tr,
                      style: const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      "${'due_date_label'.tr} ${invoice.paymentDetails.dueDate.toLocal()}".tr,
                      style: const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      "${'payment_method_label'.tr} ${invoice.paymentDetails.paymentMethod}".tr,
                      style: const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Seller and Buyer Information
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSellerSection(invoice.sellerdummy),
                _buildBuyerSection(invoice.buyer),
              ],
            ),
            pw.SizedBox(height: 80),

            // Itemized Table
            _buildItemizedTable(invoice.items),
            pw.SizedBox(height: 15),

            // VAT Summary and Total
            _buildVatSummaryAndTotal(invoice),

            // Notes and Signature
            pw.SizedBox(height: 20),
            pw.Text('terms_and_conditions_title'.tr,
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text(termsandconditions,
                style: pw.TextStyle(color: const PdfColor(0, 0, 1))),
            pw.SizedBox(height: 80),

            // Footer Signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Janusz Nowak \n",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('authorized_person_label'.tr,
                    style: const pw.TextStyle(fontSize: 8)),
                pw.Text('authorized_to_issue_invoice_label'.tr),
              ],
            ),
          ],
        );
      },
    ),
  );

  // Save or share the PDF
  await Printing.sharePdf(
    bytes: await pdf.save(),
    filename: 'invoice_${invoice.invoiceNumber}.pdf',
  );
}

// Helper function to build Seller Section
pw.Widget _buildSellerSection(Sellerdummy seller) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('seller_label'.tr,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      pw.Text(seller.companyName),
      pw.Text(seller.address),
      pw.Text("${'nip_label'.tr} ${seller.vatNumber}".tr,
          style: const pw.TextStyle(
            fontSize: 10,
          )),
    ],
  );
}

// Helper function to build Buyer Section
pw.Widget _buildBuyerSection(Buyer buyer) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('buyer_label'.tr,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      pw.Text(
        buyer.companyName,
        style: const pw.TextStyle(
          fontSize: 10,
        ),
      ),
      pw.Text(buyer.address),
      pw.Text("${'nip_label'.tr} ${buyer.vatNumber}".tr,
          style: const pw.TextStyle(
            fontSize: 10,
          )),
    ],
  );
}

// Helper function to build Itemized Table
pw.Widget _buildItemizedTable(List<InvoiceItem> items) {
  return pw.TableHelper.fromTextArray(
    cellHeight: 10,
    headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
    cellStyle: const pw.TextStyle(
      fontSize: 8,
    ),
    headers: [
       'lp_column'.tr,
       'name_column'.tr,
       'unit_column'.tr,
       'quantity_column'.tr,
       'net_price_column'.tr,
       'vat_rate_column'.tr,
       'net_value_column'.tr,
       'gross_value_column'.tr
    ],
    columnWidths: {
      0: const pw.FixedColumnWidth(25.0), // Column 1 width
      1: const pw.FixedColumnWidth(100.0), // Column 2 width
      2: const pw.FixedColumnWidth(40.0), // Column 3 width
      3: const pw.FixedColumnWidth(60.0), // Column 4 width
      4: const pw.FixedColumnWidth(60.0), // Column 5 width
      5: const pw.FixedColumnWidth(40.0), // Column 6 width
      6: const pw.FixedColumnWidth(60.0), // Column 7 width
      7: const pw.FixedColumnWidth(60.0), // Column 8 width
    },
    data: items.asMap().entries.map((entry) {
      final item = entry.value;
      final index = entry.key + 1;
      return [
        '$index',
        item.description,
        'pcs_unit'.tr,
        '${item.quantity}',
        '${item.netUnitPrice.toStringAsFixed(2)} PLN',
        '${item.vatRate}%',
        '${item.netAmount.toStringAsFixed(2)} PLN',
        '${item.grossAmount.toStringAsFixed(2)} PLN',
      ];
    }).toList(),
  );
}

// Helper function to build VAT summary and total
pw.Widget _buildVatSummaryAndTotal(Invoice invoice) {
  final vatRate = invoice.items.isNotEmpty ? invoice.items.first.vatRate : 0;
  final netTotal =
      invoice.items.fold(0.0, (double sum, item) => sum + item.netAmount);
  final vatAmount =
      invoice.items.fold(0.0, (double sum, item) => sum + item.vatAmount);
  final grossTotal =
      invoice.items.fold(0.0, (double sum, item) => sum + item.grossAmount);

  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    crossAxisAlignment:
        pw.CrossAxisAlignment.start, // Aligns columns at the top
    children: [
      pw.TableHelper.fromTextArray(
        cellHeight: 6,
        headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 8),
        columnWidths: {
          0: const pw.FixedColumnWidth(58.125),
          1: const pw.FixedColumnWidth(58.125),
          2: const pw.FixedColumnWidth(58.125),
          3: const pw.FixedColumnWidth(58.125),
        },
        headers: ['vat_rate_label'.tr, 'net_value_column'.tr, 'vat_amount_label'.tr, 'gross_value_column'.tr],
        data: [
          [
            '$vatRate%',
            '${netTotal.toStringAsFixed(2)} PLN',
            '${vatAmount.toStringAsFixed(2)} PLN',
            '${grossTotal.toStringAsFixed(2)} PLN',
          ],
        ],
      ),
      pw.SizedBox(width: 25),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, // Align to the start
        children: [
          pw.SizedBox(height: 4),
          pw.Text(
            'paid_amount_label'.tr,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'total_label'.tr,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
        ],
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end, // Align to the start
        children: [
          pw.SizedBox(height: 4),
          pw.Text(
            invoice.paidamount
                .toString(), // Adjust this to be dynamic if necessary
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            "${grossTotal.toStringAsFixed(2)} PLN",
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'in_words_label'.tr,
            style: pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            numberToWords(grossTotal.toInt()),
            style: pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    ],
  );
}

// Function to convert amount to words (Polish format)
String numberToWords(int number) {
  final IntToWords number0 = IntToWords();
  final words = number0.convert(number);
  return words;
}
