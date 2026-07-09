// cloud/api/upload.dart

import 'package:cloud/providers/providers.dart';
import 'package:core/platform/api_services.dart';
import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:cross_file/cross_file.dart' show XFile;
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart' as mime;
import 'dart:convert';



Future<Map<String, dynamic>?> uploadFileToCloud({
  required dynamic file,
  required String uploadUrl,
  String? folderId,
  String? description,
  List<String>? tags,
  bool? isSecured,
  String? appLabel,
  String? model,
  String? objectId,
  String? relationType,
  String? fileType,
  void Function(double progress)? onProgress,
  dynamic ref,
}) async {
  String fileName = '';
  Uint8List? fileBytes;
  String? filePath; // jeśli mamy ścieżkę, lepiej streamować z pliku
  String mimeType = 'application/octet-stream';

  try {
    // 1) PlatformFile (FilePicker)
    if (file is PlatformFile) {
      fileName = file.name;
      if (file.bytes != null) {
        fileBytes = file.bytes!;
      } else if (file.path != null) {
        filePath = file.path!;
      }
    }
    // 2) XFile (desktop_drop)
    else if (file is XFile) {
      // nazwa dostępna zwykle zawsze; fallback na basename ze ścieżki
      fileName = (file.name.isNotEmpty)
          ? file.name
          : (file.path.isNotEmpty ? p.basename(file.path) : 'file');

      if (kIsWeb || file.path.isEmpty) {
        // Web/bez-ścieżki: czytamy do pamięci
        fileBytes = await file.readAsBytes();
      } else {
        // Desktop/mobile: mamy ścieżkę
        filePath = file.path;
      }
    }
    // 3) dart:io File
    else if (file is File) {
      filePath = file.path;
      fileName = p.basename(filePath);
    }
    // 4) Inne = błąd
    else {
      throw Exception("Nieobsługiwany typ pliku: ${file.runtimeType}");
    }

    // MIME z rozszerzenia (best-effort)
    final detected = mime.lookupMimeType(fileName);
    if (detected != null) mimeType = detected;

    // Budujemy MultipartFile z bytes LUB z file path (preferowane dla dużych plików)
    MultipartFile multipart;
    if (fileBytes != null) {
      multipart = MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      );
    } else if (filePath != null) {
      multipart = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      );
    } else {
      throw Exception('Brak danych pliku do wysłania');
    }


  final formData = FormData.fromMap({
    'file': multipart,
    'original_name': fileName,
    if (folderId != null)      'folder': folderId,
    if (description != null)   'description': description,
    if (tags != null)          'tags': jsonEncode(tags),     // backend i tak przyjmie listę/JSON
    if (isSecured != null)     'is_secured': isSecured,      // DRF zamieni na string w multipart
    if (appLabel != null)      'app_label': appLabel,
    if (model != null)         'model': model,
    if (objectId != null)      'object_id': objectId,        // string OK
    if (relationType != null)  'relation_type': relationType,
    if (fileType != null)      'file_type': fileType,        // hint — jeśli chcesz użyć po stronie DRF
  });

    // UŻYWAJ przekazanego uploadUrl (bez hard-code)
    final resp = await ApiServices.post(
      uploadUrl, // <- tu zmiana
      hasToken: true,
      formData: formData,
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) onProgress(sent / total);
      },
      ref: ref,
    );
    if (resp == null || (resp.statusCode ?? 201) < 400) {
      ref.invalidate(cloudExplorerProvider);
    }

    if (resp == null || (resp.statusCode ?? 500) >= 400) {
      throw Exception('Upload failed: ${resp?.statusCode} ${resp?.data}');
    }

    final raw = resp?.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  } catch (e) {
    throw Exception(e.toString());
  }
}

