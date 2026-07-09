import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:core/platform/api_services.dart';

import '../provider/urls.dart';
import 'emma_attachment.dart';

/// Załączniki bieżącego pola wejściowego czatu Emmy: dodawanie (plik/paste),
/// upload na `/emma/attachments/upload/`, usuwanie i czyszczenie po wysłaniu.
class EmmaAttachmentController extends StateNotifier<List<EmmaAttachment>> {
  EmmaAttachmentController() : super(const []);

  static const _uploadUrl = '${URLsEmma.baseUrl}attachments/upload/';

  static const _imageExts = {
    'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'tiff', 'tif', 'heic', 'heif',
  };

  int _seq = 0;
  String _nextId() => 'att_${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  bool get isBusy => state.any((a) => a.isUploading);
  bool get hasReady => state.any((a) => a.isReady);

  /// Gotowe obrazy → payload `images`.
  List<Map<String, dynamic>> imagesPayload() =>
      state.map((a) => a.toImagePayload()).whereType<Map<String, dynamic>>().toList();

  /// Gotowe dokumenty → payload `documents`.
  List<Map<String, dynamic>> documentsPayload() =>
      state.map((a) => a.toDocumentPayload()).whereType<Map<String, dynamic>>().toList();

  void removeAttachment(String id) {
    state = state.where((a) => a.id != id).toList();
  }

  void clear() {
    state = const [];
  }

  /// Obraz ze schowka (Ctrl+V). Zwraca true, jeśli był obraz do wklejenia.
  Future<bool> pasteFromClipboard() async {
    Uint8List? bytes;
    try {
      bytes = await Pasteboard.image;
    } catch (_) {
      bytes = null;
    }
    if (bytes == null || bytes.isEmpty) return false;

    final name = 'wklejone_${DateTime.now().millisecondsSinceEpoch}.png';
    await _addImage(bytes, name: name, mime: 'image/png');
    return true;
  }

  /// Wybór plików z dysku (obrazy + dokumenty).
  Future<void> pickFiles() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.any,
      );
    } catch (_) {
      return;
    }
    if (result == null) return;

    for (final f in result.files) {
      final data = f.bytes;
      if (data == null || data.isEmpty) continue;
      final ext = (f.extension ?? '').toLowerCase();
      if (_imageExts.contains(ext)) {
        await _addImage(data, name: f.name, mime: 'image/$ext');
      } else {
        await _addDocument(data, name: f.name, ext: ext);
      }
    }
  }

  /// Dodaje plik z surowych bajtów (drag&drop z pulpitu) — sam wykrywa obraz/dokument.
  Future<void> addFileBytes(Uint8List bytes, String name) async {
    if (bytes.isEmpty) return;
    final ext = (name.contains('.') ? name.split('.').last : '').toLowerCase();
    if (_imageExts.contains(ext)) {
      await _addImage(bytes, name: name, mime: 'image/$ext');
    } else {
      await _addDocument(bytes, name: name, ext: ext);
    }
  }

  Future<void> _addImage(Uint8List bytes, {required String name, required String mime}) async {
    final att = EmmaAttachment(
      id: _nextId(),
      kind: EmmaAttachmentKind.image,
      name: name,
      mimeType: mime,
      sizeBytes: bytes.length,
      previewBytes: bytes,
    );
    state = [...state, att];
    await _upload(att, bytes);
  }

  Future<void> _addDocument(Uint8List bytes, {required String name, required String ext}) async {
    final att = EmmaAttachment(
      id: _nextId(),
      kind: EmmaAttachmentKind.document,
      name: name,
      sizeBytes: bytes.length,
    );
    state = [...state, att];
    await _upload(att, bytes);
  }

  void _patch(String id, EmmaAttachment Function(EmmaAttachment) fn) {
    state = [
      for (final a in state) if (a.id == id) fn(a) else a,
    ];
  }

  Future<void> _upload(EmmaAttachment att, Uint8List bytes) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: att.name),
      });

      final resp = await ApiServices.post(_uploadUrl, formData: form);
      final data = resp?.data;

      if (resp == null || resp.statusCode == null || resp.statusCode! >= 400 ||
          data is! Map || data['ok'] != true) {
        final err = (data is Map ? data['error']?.toString() : null) ??
            'Upload nie powiódł się.';
        _patch(att.id, (a) => a.copyWith(
              status: EmmaAttachmentStatus.error,
              errorText: err,
            ));
        return;
      }

      final kind = (data['kind'] ?? '').toString();
      if (kind == 'image') {
        _patch(att.id, (a) => a.copyWith(
              status: EmmaAttachmentStatus.ready,
              url: (data['url'] ?? data['image_url'] ?? '').toString(),
              mimeType: (data['mime_type'] ?? a.mimeType).toString(),
              sizeBytes: (data['size'] as num?)?.toInt() ?? a.sizeBytes,
            ));
      } else {
        _patch(att.id, (a) => a.copyWith(
              status: EmmaAttachmentStatus.ready,
              text: (data['text'] ?? '').toString(),
              chars: (data['chars'] as num?)?.toInt(),
              truncated: data['truncated'] == true,
              mimeType: (data['mime_type'] ?? a.mimeType).toString(),
              url: (data['url'] ?? '').toString(),
            ));
      }
    } catch (e) {
      _patch(att.id, (a) => a.copyWith(
            status: EmmaAttachmentStatus.error,
            errorText: 'Błąd uploadu',
          ));
    }
  }
}

/// Per-widget (autoDispose) — każde pole wejściowe ma własny zestaw załączników.
final emmaAttachmentControllerProvider = StateNotifierProvider.autoDispose<
    EmmaAttachmentController, List<EmmaAttachment>>(
  (ref) => EmmaAttachmentController(),
);
