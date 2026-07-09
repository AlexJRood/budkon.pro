// Used on non-web builds (do nothing; the real impl is in pdf_downloader.dart)
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> savePdfBytes(Uint8List bytes, String filename) async {
  if (kIsWeb) {
    // On web this function is replaced by the web version via conditional import.
    // Fallback: open the print dialog (still lets user save as PDF).
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  } else {
    // System share/save sheet (Files/Downloads, AirDrop, etc.)
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
