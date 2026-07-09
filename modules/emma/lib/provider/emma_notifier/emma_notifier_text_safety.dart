part of '../emma_notifier.dart';

/// Text, JSON and primitive parsing helpers.
///
/// These helpers are used by REST, WebSocket and local-engine code. They are
/// intentionally defensive because streamed model output can contain partial or
/// malformed text chunks.
extension EmmaNotifierTextSafety on ChatAiMessagesNotifier {
  /// Sanitizes text before it reaches Flutter widgets.
  ///
  /// It removes null bytes, replaces unsupported control characters and repairs
  /// broken UTF-16 surrogate pairs.
  String _sanitizeFlutterText(String value) {
    if (value.isEmpty) return value;

    final buffer = StringBuffer();
    final units = value.codeUnits;

    var i = 0;

    while (i < units.length) {
      final unit = units[i];

      final isHighSurrogate = unit >= 0xD800 && unit <= 0xDBFF;
      final isLowSurrogate = unit >= 0xDC00 && unit <= 0xDFFF;

      if (isHighSurrogate) {
        if (i + 1 < units.length) {
          final next = units[i + 1];
          final nextIsLow = next >= 0xDC00 && next <= 0xDFFF;

          if (nextIsLow) {
            buffer.write(String.fromCharCodes([unit, next]));
            i += 2;
            continue;
          }
        }

        buffer.write('\uFFFD');
        i += 1;
        continue;
      }

      if (isLowSurrogate) {
        buffer.write('\uFFFD');
        i += 1;
        continue;
      }

      if (unit == 0) {
        i += 1;
        continue;
      }

      if (unit < 32 && unit != 9 && unit != 10 && unit != 13) {
        buffer.write(' ');
        i += 1;
        continue;
      }

      buffer.writeCharCode(unit);
      i += 1;
    }

    return buffer.toString();
  }

  /// Converts any dynamic value into UI-safe text.
  String _safeText(dynamic value) {
    return _sanitizeFlutterText((value ?? '').toString());
  }

  /// Normalizes message content for optimistic-message matching.
  String _normalizeMessageForMatch(String value) {
    return _sanitizeFlutterText(value).trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Safely parses integer-like values from JSON payloads.
  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  /// Parses backend timestamps without allowing malformed dates to crash flows.
  ///
  /// Backend serializuje czas w UTC (+00:00). Bez `.toLocal()` DateTime zostaje
  /// w UTC, a widok czytał `timestamp.hour` — stąd 19:55 zamiast 21:55.
  DateTime _parseDateTimeSafe(dynamic raw) {
    if (raw is String) {
      return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Extracts a typed JSON-like map from a dynamic value.
  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  /// Extracts a list of typed JSON-like maps from a dynamic value.
  List<Map<String, dynamic>> _extractListOfMaps(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Returns the latest user content from a local-engine message list.
  String _lastUserContent(List<Map<String, dynamic>> messages) {
    for (final message in messages.reversed) {
      if ((message['role'] ?? '').toString() == 'user') {
        return _safeText(message['content']);
      }
    }
    


    return '';
  }
}
