// Only compiled on web
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> savePdfBytes(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..download = filename;
  anchor.click();
  html.Url.revokeObjectUrl(url);
}
