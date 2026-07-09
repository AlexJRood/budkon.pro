import 'dart:html' as html;

Future<String?> saveOrDownloadPdf({
  required List<int> bytes,
  required String fileName,
}) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  html.Url.revokeObjectUrl(url);
  return null; 
}
