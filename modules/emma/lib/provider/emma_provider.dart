import 'dart:convert';
import 'dart:typed_data';

import 'package:emma/model/chat_room.dart';
import 'package:emma/provider/urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';

import 'package:emma/sync/emma_local_db.dart';
import 'package:emma/sync/emma_sync_service.dart';
import 'package:emma/sync/emma_local_ids.dart';

final emmaChatBootstrappingProvider = StateProvider<bool>((ref) => false);

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

class ChatAiRoomsProvider extends StateNotifier<List<ChatRoom>> {
  final Ref ref;

  ChatAiRoomsProvider({required this.ref}) : super(const []);

  /// Diagnostic-only: the reason the most recent createRoomAndReturn() call
  /// fell back to an offline room instead of a real cloud session. Surfaced
  /// in the UI so a failure can be root-caused from a device without
  /// attaching a debugger.
  String? lastCreateRoomError;

  /// Loads chat sessions.
  ///
  /// Returns `true` when the server fetch succeeded (HTTP 200), regardless of
  /// whether the resulting list is empty. Returns `false` when the network
  /// request failed or errored — callers use this to distinguish an empty
  /// account from an actual network problem.
  Future<bool> getRooms() async {
    final canUseLocalDb = !kIsWeb;
    final localDb = canUseLocalDb ? EmmaLocalDb.instance : null;
    var fetchSucceeded = false;

    try {
      if (localDb != null) {
        final localRooms = await localDb.getRooms();

        if (localRooms.isNotEmpty) {
          state = localRooms;
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: local rooms load error: $e\n$stack');
      }
    }

    try {
      if (canUseLocalDb) {
        await ref.read(emmaSyncServiceProvider).syncNow();
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: sync before rooms failed: $e\n$stack');
      }
    }

    try {
      final response = await ApiServices.get(
        URLsEmma.emmaChatSession,
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        fetchSucceeded = true;
        final decodedData = _decodeApiBody(response.data);

        final List<dynamic> rawList = decodedData is List
            ? decodedData
            : (decodedData is Map && decodedData['results'] is List)
                ? decodedData['results'] as List
                : const <dynamic>[];

        final rooms = rawList
            .whereType<Map>()
            .map((e) => ChatRoom.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        if (localDb != null) {
          // Persisting to the local DB is best-effort: a SQLite failure must
          // not discard the rooms we just fetched from the server, otherwise
          // the sidebar shows a false "network error" on platforms that route
          // through the local DB (e.g. iOS).
          try {
            for (final room in rooms) {
              await localDb.upsertRoom(
                room,
                clientUuid: 'server_session_${room.id}',
                syncStatus: 'synced',
              );
            }

            state = await localDb.getRooms();
          } catch (e, stack) {
            if (kDebugMode) {
              debugPrint(
                'Emma: rooms local persist failed, using server list: $e\n$stack',
              );
            }
            state = rooms;
          }
        } else {
          state = rooms;
        }
      } else {
        if (kDebugMode) {
          debugPrint('Emma: fetch rooms failed: ${response?.statusCode}');
          debugPrint('Emma: fetch rooms body type: ${response?.data.runtimeType}');
          debugPrint('Emma: fetch rooms body: ${response?.data}');
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: fetch rooms error: $e\n$stack');
      }
    }

    return fetchSucceeded;
  }

  Future<void> createRoom() async {
    await createRoomAndReturn();
  }

  Future<ChatRoom?> createRoomAndReturn({String title = 'New chat'}) async {
    final canUseLocalDb = !kIsWeb;
    final localDb = canUseLocalDb ? EmmaLocalDb.instance : null;

    lastCreateRoomError = null;

    try {
      final response = await ApiServices.post(
        URLsEmma.emmaChatSession,
        hasToken: true,
        ref: ref,
        data: {'title': title},
      );

      if (response != null && response.statusCode == 201) {
        ChatRoom? room;

        try {
          final decoded = _decodeApiBody(response.data);

          if (decoded is Map<String, dynamic>) {
            room = ChatRoom.fromJson(decoded);
          } else if (decoded is Map) {
            room = ChatRoom.fromJson(Map<String, dynamic>.from(decoded));
          }
        } catch (e, stack) {
          lastCreateRoomError = 'decode error (201): $e';

          if (kDebugMode) {
            debugPrint('Emma: create room decode error: $e\n$stack');
            debugPrint('Emma: create room raw body: ${response.data}');
          }
        }

        if (room != null) {
          final createdRoom = room;

          if (localDb != null) {
            // Persisting to the local DB is best-effort: the cloud session
            // already exists at this point, so a SQLite failure here must
            // not discard it and fall through to the offline-room fallback
            // below (that previously happened, e.g. via sqflite_darwin's
            // "not an error" PRAGMA bug on iOS, silently orphaning the just
            // created cloud room and leaving the composer stuck).
            try {
              await localDb.upsertRoom(
                createdRoom,
                clientUuid: 'server_session_${createdRoom.id}',
                syncStatus: 'synced',
              );
            } catch (e, stack) {
              if (kDebugMode) {
                debugPrint('Emma: create room local persist failed: $e\n$stack');
              }
            }
          }

          state = [
            createdRoom,
            ...state.where((r) => r.id != createdRoom.id),
          ];

          return createdRoom;
        }

        await getRooms();
        return state.isNotEmpty ? state.first : null;
      } else {
        lastCreateRoomError =
            'HTTP ${response?.statusCode}: ${response?.data}';

        if (kDebugMode) {
          debugPrint('Emma: create room failed: ${response?.statusCode}');
          debugPrint('Emma: create room body type: ${response?.data.runtimeType}');
          debugPrint('Emma: create room body: ${response?.data}');
        }
      }
    } catch (e, stack) {
      lastCreateRoomError = '$e';

      if (kDebugMode) {
        debugPrint('Emma: create room cloud failed, using local: $e\n$stack');
      }
    }

    if (localDb == null) {
      return null;
    }

    final localId = EmmaLocalIds.negativeNow();
    final now = DateTime.now().toIso8601String();
    final clientUuid = EmmaLocalIds.sessionUuid(localId);

    final localRoom = ChatRoom.fromJson({
      'id': localId,
      'client_uuid': clientUuid,
      'title': title,
      'created_at': now,
      'last_activity_at': now,
      'meta': {
        'local_only': true,
        'sync_status': 'pending_create',
      },
    });

    await localDb.upsertRoom(
      localRoom,
      clientUuid: clientUuid,
      syncStatus: 'pending_create',
    );

    state = [
      localRoom,
      ...state.where((r) => r.id != localRoom.id),
    ];

    return localRoom;
  }

  Future<void> removeRoom(String id) async {
    try {
      final response = await ApiServices.delete(
        URLsEmma.emmaChatSessionId(id),
        hasToken: true,
      );

      if (response != null &&
          (response.statusCode == 204 || response.statusCode == 200)) {
        await getRooms();
      } else {
        if (kDebugMode) {
          debugPrint('Emma: delete room failed: ${response?.statusCode}');
          debugPrint('Emma: delete room body type: ${response?.data.runtimeType}');
          debugPrint('Emma: delete room body: ${response?.data}');
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Emma: delete room error: $e\n$stack');
      }
    }
    
  }

  void updateSessionTitle(int sessionId, String newTitle) {
    state = [
      for (final room in state)
        if (room.id == sessionId) room.copyWith(title: newTitle) else room,
    ];
  }
}

final chatAiRoomsProvider =
    StateNotifierProvider<ChatAiRoomsProvider, List<ChatRoom>>((ref) {
  return ChatAiRoomsProvider(ref: ref);
});

final selectedAiRoomProvider = StateProvider<String>((ref) => '');