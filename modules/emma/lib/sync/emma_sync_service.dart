import 'dart:convert';
import 'dart:typed_data';

import 'package:emma/provider/urls.dart';
import 'package:emma/sync/emma_local_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

Object? _decodeApiBody(dynamic body) {
  try {
    if (body == null) return null;

    if (body is Uint8List) {
      final text = utf8.decode(body);
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    }

    if (body is List<int>) {
      final text = utf8.decode(body);
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    }

    if (body is String) {
      if (body.trim().isEmpty) return null;
      return jsonDecode(body);
    }

    if (body is Map || body is List) {
      return body;
    }

    final text = body.toString();
    if (text.trim().isEmpty) return null;

    return jsonDecode(text);
  } catch (e, stack) {
    if (kDebugMode) {
      debugPrint(
        'Emma: decode API body failed. '
        'type=${body.runtimeType}, value=$body, error=$e\n$stack',
      );
    }
    return null;
  }
}

Map<String, dynamic> _decodeMap(dynamic body) {
  final decoded = _decodeApiBody(body);

  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }

  return <String, dynamic>{};
}

Map<String, dynamic> _safeLocalJsonMap(dynamic value) {
  try {
    if (value == null) return <String, dynamic>{};

    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Uint8List) {
      final text = utf8.decode(value);
      if (text.trim().isEmpty) return <String, dynamic>{};

      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);

      return <String, dynamic>{};
    }

    if (value is List<int>) {
      final text = utf8.decode(value);
      if (text.trim().isEmpty) return <String, dynamic>{};

      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);

      return <String, dynamic>{};
    }

    final text = value.toString();
    if (text.trim().isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(text);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
  } catch (e, stack) {
    if (kDebugMode) {
      debugPrint(
        'Emma: local JSON decode failed. '
        'type=${value.runtimeType}, value=$value, error=$e\n$stack',
      );
    }
  }

  return <String, dynamic>{};
}

Map<String, dynamic> _safeMeta(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

class EmmaSyncService {
  EmmaSyncService(this.ref);

  final Ref ref;

  bool _isSyncing = false;

  Future<void> syncNow() async {
    if (_isSyncing) {
      if (kDebugMode) {
        debugPrint('Emma sync skipped: already syncing');
      }
      return;
    }

    _isSyncing = true;

    try {
      final db = EmmaLocalDb.instance;

      final lastSyncAt = await db.getMeta('last_sync_at');
      final pendingSessions = await db.pendingSessions();
      final pendingMessages = await db.pendingMessages();

      final sessionsPayload = pendingSessions.map((row) {
        final raw = _safeLocalJsonMap(row['json']);

        return {
          'local_id': row['local_id'],
          'server_id': row['server_id'],
          'client_uuid': row['client_uuid'],
          'title': row['title'],
          'created_at': row['created_at'],
          'last_activity_at': row['last_activity_at'],
          'language': raw['language'] ?? '',
          'source': raw['source'] ?? 'mobile',
          'is_archived': raw['is_archived'] ?? false,
          'meta': _safeMeta(raw['meta']),
        };
      }).toList();

      final messagesPayload = pendingMessages.map((row) {
        final raw = _safeLocalJsonMap(row['json']);

        return {
          'local_id': row['local_id'],
          'server_id': row['server_id'],
          'client_uuid': row['client_uuid'],
          'session_local_id': row['session_local_id'],
          'session_server_id': row['session_server_id'],
          'session_client_uuid': row['session_client_uuid'],
          'role': row['role'],
          'kind': row['kind'],
          'content': row['content'],
          'created_at': row['created_at'],
          'meta': _safeMeta(raw['meta']),
        };
      }).toList();

      final response = await ApiServices.post(
        URLsEmma.emmaChatSync,
        hasToken: true,
        ref: ref,
        data: {
          'last_sync_at': lastSyncAt,
          'sessions': sessionsPayload,
          'messages': messagesPayload,
        },
      );

      if (response == null || response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('Emma sync failed: ${response?.statusCode}');
          debugPrint('Emma sync body type: ${response?.data.runtimeType}');
          debugPrint('Emma sync body: ${response?.data}');
        }
        return;
      }

      final data = _decodeMap(response.data);

      if (data.isEmpty) {
        if (kDebugMode) {
          debugPrint('Emma sync failed: empty or invalid response body');
          debugPrint('Emma sync body type: ${response.data.runtimeType}');
          debugPrint('Emma sync body: ${response.data}');
        }
        return;
      }

      final sessionIdMap = data['session_id_map'] is Map
          ? Map<String, dynamic>.from(data['session_id_map'] as Map)
          : <String, dynamic>{};

      final messageIdMap = data['message_id_map'] is Map
          ? Map<String, dynamic>.from(data['message_id_map'] as Map)
          : <String, dynamic>{};

      await db.applySessionIdMap(sessionIdMap);
      await db.applyMessageIdMap(messageIdMap);

      final sessions = data['sessions'];
      if (sessions is List) {
        for (final item in sessions) {
          if (item is Map<String, dynamic>) {
            await db.upsertServerRoomJson(item);
          } else if (item is Map) {
            await db.upsertServerRoomJson(Map<String, dynamic>.from(item));
          }
        }
      }

      final messages = data['messages'];
      if (messages is List) {
        for (final item in messages) {
          if (item is Map<String, dynamic>) {
            await db.upsertServerMessageJson(item);
          } else if (item is Map) {
            await db.upsertServerMessageJson(Map<String, dynamic>.from(item));
          }
        }
      }

      final serverTime = data['server_time']?.toString();
      if (serverTime != null && serverTime.trim().isNotEmpty) {
        await db.setMeta('last_sync_at', serverTime);
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma sync error: $e\n$stack');
      }
    } finally {
      _isSyncing = false;
    }
  }
}

final emmaSyncServiceProvider = Provider<EmmaSyncService>((ref) {
  return EmmaSyncService(ref);
});