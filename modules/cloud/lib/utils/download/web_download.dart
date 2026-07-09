
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:dio/dio.dart';

Future<void> webDownloadUrl(String url, String filename) async {
  final dio = Dio();

  final resp = await dio.get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes),
  );

  final bytes = resp.data;
  if (bytes == null || bytes.isEmpty) throw 'Failed to download image';

  final blob = html.Blob([Uint8List.fromList(bytes)]);
  final blobUrl = html.Url.createObjectUrlFromBlob(blob);

  final a = html.AnchorElement(href: blobUrl)
    ..download = filename
    ..style.display = 'none';

  html.document.body?.append(a);
  a.click();
  a.remove();

  html.Url.revokeObjectUrl(blobUrl);
}

Future<void> webDownloadBytes(
    List<int> bytes,
    String fileName, {
      String mimeType = 'application/octet-stream',
    }) async {
  final blob = html.Blob([bytes], mimeType);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: objectUrl)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  html.Url.revokeObjectUrl(objectUrl);
}