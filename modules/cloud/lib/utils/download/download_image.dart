import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:cloud/models/file.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'web_download_stub.dart' if (dart.library.html) 'web_download.dart';

Future<void> downloadImageFile(CloudFile file) async {
  final url = _resolveCloudFileUrl(file);
  final fileName = file.name.trim().isEmpty ? 'image.png' : file.name.trim();

  final lower = fileName.toLowerCase();
  final ext =
      lower.endsWith('.png')
          ? 'png'
          : (lower.endsWith('.jpg') || lower.endsWith('.jpeg'))
          ? 'jpg'
          : lower.endsWith('.webp')
          ? 'webp'
          : lower.endsWith('.gif')
          ? 'gif'
          : 'png';
  if (kIsWeb) {
    await webDownloadUrl(url, fileName);
    return;
  }
  final dio = Dio();
  final resp = await dio.get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes),
  );

  final bytes = resp.data;
  if (bytes == null || bytes.isEmpty) throw 'Failed to download image';

  final mimeType =
      ext == 'jpg'
          ? MimeType.jpeg
          : ext == 'png'
          ? MimeType.png
          : ext == 'webp'
          ? MimeType.webp
          : ext == 'gif'
          ? MimeType.gif
          : MimeType.png;

  final baseName = fileName.replaceAll(
    RegExp(r'\.(png|jpg|jpeg|webp|gif)$', caseSensitive: false),
    '',
  );

  await FileSaver.instance.saveAs(
    name: baseName,
    bytes: Uint8List.fromList(bytes),
    fileExtension: ext,
    mimeType: mimeType,
    includeExtension: true,
  );
}

String _resolveCloudFileUrl(CloudFile file) {
  final raw =
      (file.publicUrl?.trim().isNotEmpty == true)
          ? file.publicUrl!.trim()
          : file.url.trim();

  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  return 'https://www.superbee.cloud$raw';
}
