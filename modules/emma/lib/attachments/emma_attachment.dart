import 'dart:typed_data';

/// Rodzaj załącznika czatu Emmy.
enum EmmaAttachmentKind { image, document }

/// Status uploadu pojedynczego załącznika.
enum EmmaAttachmentStatus { uploading, ready, error }

/// Pojedynczy załącznik dołączany do wiadomości (przed i po uploadzie).
///
/// Obrazy po uploadzie mają [url] (http, z Cloud Storage). Dokumenty mają
/// wyekstrahowany [text] (server-side) gotowy do wysłania w payloadzie.
class EmmaAttachment {
  final String id;
  final EmmaAttachmentKind kind;
  final String name;
  final String mimeType;
  final int sizeBytes;

  /// Podgląd (miniatura) dla obrazu — trzymany tylko do czasu wyświetlenia.
  final Uint8List? previewBytes;

  final EmmaAttachmentStatus status;
  final String? errorText;

  // Po uploadzie:
  final String? url; // obraz (http) lub opcjonalny url dokumentu
  final String? text; // dokument: wyekstrahowany tekst
  final int? chars;
  final bool truncated;

  const EmmaAttachment({
    required this.id,
    required this.kind,
    required this.name,
    this.mimeType = '',
    this.sizeBytes = 0,
    this.previewBytes,
    this.status = EmmaAttachmentStatus.uploading,
    this.errorText,
    this.url,
    this.text,
    this.chars,
    this.truncated = false,
  });

  bool get isImage => kind == EmmaAttachmentKind.image;
  bool get isReady => status == EmmaAttachmentStatus.ready;
  bool get isUploading => status == EmmaAttachmentStatus.uploading;
  bool get hasError => status == EmmaAttachmentStatus.error;

  EmmaAttachment copyWith({
    EmmaAttachmentStatus? status,
    String? errorText,
    String? url,
    String? text,
    int? chars,
    bool? truncated,
    String? mimeType,
    int? sizeBytes,
  }) {
    return EmmaAttachment(
      id: id,
      kind: kind,
      name: name,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      previewBytes: previewBytes,
      status: status ?? this.status,
      errorText: errorText ?? this.errorText,
      url: url ?? this.url,
      text: text ?? this.text,
      chars: chars ?? this.chars,
      truncated: truncated ?? this.truncated,
    );
  }

  /// Wpis do tablicy `images` w payloadzie WS (tylko gotowe obrazy).
  Map<String, dynamic>? toImagePayload() {
    if (!isImage || !isReady || (url ?? '').isEmpty) return null;
    return {
      'image_url': url,
      'url': url,
      'mime_type': mimeType,
      'name': name,
      'size': sizeBytes,
    };
  }

  /// Wpis do tablicy `documents` w payloadzie WS (tylko gotowe dokumenty).
  Map<String, dynamic>? toDocumentPayload() {
    if (isImage || !isReady || (text ?? '').isEmpty) return null;
    return {
      'name': name,
      'mime_type': mimeType,
      'text': text,
      'chars': chars ?? (text ?? '').length,
      'truncated': truncated,
      if ((url ?? '').isNotEmpty) 'url': url,
    };
  }
}
