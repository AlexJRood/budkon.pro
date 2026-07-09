import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> saveOrDownloadPdf({
  required List<int> bytes,
  required String fileName,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
