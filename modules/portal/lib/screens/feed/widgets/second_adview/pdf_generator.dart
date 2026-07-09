import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;


final pdfGeneratorProvider = StateNotifierProvider<PdfGeneratorNotifier, bool>(
  (ref) => PdfGeneratorNotifier(),
);

class PdfGeneratorNotifier extends StateNotifier<bool> {
  PdfGeneratorNotifier() : super(false);

  Future<void> generatePdf(dynamic adFeedPop) async {
    state = true;

    final pdfData = await _generatePdf(adFeedPop.images, adFeedPop);

    if (pdfData != null) {
      // await Printing.sharePdf(bytes: pdfData, filename: 'invoice.pdf');
    }

    state = false;
  }

  Future<Uint8List?> _generatePdf(
      List<String> imageUrls, dynamic adFeedPop) async {
    final pdf = pw.Document();
    final images = <pw.ImageProvider>[];
    final customFormat = NumberFormat.decimalPattern('fr');
    final formattedPrice = customFormat.format(adFeedPop.price);

    // Load the DejaVu Sans font
    final font =
        pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));

    // Download and convert images
    for (var imageUrl in imageUrls) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final webpBytes = response.bodyBytes;
          final webpImage = img.decodeWebP(webpBytes);
          if (webpImage != null) {
            final jpgBytes = img.encodeJpg(webpImage);
            images.add(pw.MemoryImage(Uint8List.fromList(jpgBytes)));
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error downloading or converting image: $e');
      }
    }

    if (images.isEmpty) return null;

    final titleStyle = pw.TextStyle(
      font: font,
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final priceStyle = pw.TextStyle(
      font: font,
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(10),
        build: (context) => pw.Column(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              height: 80,
              color: PdfColors.blue700,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(adFeedPop.country, style: titleStyle),
                      pw.Text(adFeedPop.city, style: titleStyle),
                    ],
                  ),
                  pw.Text('$formattedPrice ${adFeedPop.currency}',
                      style: priceStyle),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty)
                  pw.Container(
                    child: pw.Image(images[0], fit: pw.BoxFit.fill),
                    width: 380,
                    height: 275,
                  ),
                pw.SizedBox(width: 10),
                if (images.length > 1)
                  pw.Column(
                    children: [
                      if (images.length > 1)
                        pw.Container(
                          child: pw.Image(images[1], fit: pw.BoxFit.fill),
                          width: 180,
                          height: 132.5,
                        ),
                      pw.SizedBox(height: 10),
                      if (images.length > 2)
                        pw.Container(
                          child: pw.Image(images[2], fit: pw.BoxFit.fill),
                          width: 180,
                          height: 132.5,
                        ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                if (images.length > 3)
                  pw.Container(
                    child: pw.Image(images[3], fit: pw.BoxFit.fill),
                    width: 185,
                    height: 132.5,
                  ),
                pw.SizedBox(width: 10),
                if (images.length > 4)
                  pw.Container(
                    child: pw.Image(images[4], fit: pw.BoxFit.fill),
                    width: 185,
                    height: 132.5,
                  ),
                pw.SizedBox(width: 10),
                if (images.length > 5)
                  pw.Container(
                    child: pw.Image(images[5], fit: pw.BoxFit.fill),
                    width: 180,
                    height: 132.5,
                  ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(25),
                  width: 380,
                  height: 300,
                  child: pw.Text(adFeedPop.description,
                      style: pw.TextStyle(font: font)),
                ),
                pw.SizedBox(width: 10),
               
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}
