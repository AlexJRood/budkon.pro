import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<Uint8List?> _captureChartPng(GlobalKey chartKey) async {
  final boundary =
      chartKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
  if (boundary == null) return null;

  final ui.Image image =
      await boundary.toImage(pixelRatio: 3.0);
  final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return null;
  return byteData.buffer.asUint8List();
}

Future<void> exportFinanceChartAsPng(
  BuildContext context,
  GlobalKey chartKey,
) async {
  final pngBytes = await _captureChartPng(chartKey);
  if (pngBytes == null) return;

  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/finance_chart_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(pngBytes);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${'chart_saved_as_png_prefix'.tr} ${file.path}'),
    ),
  );
}

Future<void> exportFinanceChartAsPdf(
  BuildContext context,
  GlobalKey chartKey,
) async {
  final pngBytes = await _captureChartPng(chartKey);
  if (pngBytes == null) return;

  final pdf = pw.Document();
  final image = pw.MemoryImage(pngBytes);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
             'finance_chart_title'.tr,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Image(image),
          ],
        );
      },
    ),
  );

  await Printing.sharePdf(
    bytes: await pdf.save(),
    filename:
        'finance_chart_${DateTime.now().millisecondsSinceEpoch}.pdf',
  );
}
