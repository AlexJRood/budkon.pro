import 'dart:typed_data';

import 'package:cloud/models/file.dart';
import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:html' as html;

String _resolveCloudFileUrl(CloudFile file) {
  final raw =
      (file.publicUrl?.trim().isNotEmpty == true)
          ? file.publicUrl!.trim()
          : file.url.trim();

  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  return 'https://www.superbee.cloud$raw';
}

String _guessExtFromMime(String? mime) {
  final m = (mime ?? '').toLowerCase();
  if (m.contains('png')) return 'png';
  if (m.contains('jpeg') || m.contains('jpg')) return 'jpg';
  if (m.contains('webp')) return 'webp';
  if (m.contains('gif')) return 'gif';
  return 'bin';
}

Future<void> downloadCloudImageAllPlatforms(CloudFile file) async {
  final url = _resolveCloudFileUrl(file);

  final resp = await Dio().get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes),
  );

  final bytes = Uint8List.fromList(resp.data ?? const <int>[]);
  if (bytes.isEmpty) throw 'Empty file';

  final name = file.name.trim().isNotEmpty ? file.name.trim() : 'image';
  final hasExt = name.contains('.') && name.split('.').last.length <= 5;
  final ext = hasExt ? name.split('.').last : _guessExtFromMime(file.mimeType);
  final baseName =
      hasExt
          ? name.split('.').sublist(0, name.split('.').length - 1).join('.')
          : name;

  if (kIsWeb) {
    final blob = html.Blob([bytes]);
    final objectUrl = html.Url.createObjectUrlFromBlob(blob);

    final a =
        html.AnchorElement(href: objectUrl)
          ..download = '$baseName.$ext'
          ..style.display = 'none';

    html.document.body!.children.add(a);
    a.click();
    a.remove();
    html.Url.revokeObjectUrl(objectUrl);
    return;
  }

  await FileSaver.instance.saveFile(
    name: baseName,
    bytes: bytes,
    fileExtension: ext,
    mimeType: MimeType.other,
  );
}
