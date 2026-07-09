// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

bool downloadPdfOnWeb(List<int> bytes, String filename) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  html.Url.revokeObjectUrl(url);
  return true;
}
