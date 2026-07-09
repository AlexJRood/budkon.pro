import 'dart:convert';

import 'package:emma/library/emma_local_model_installer_types.dart';
import 'package:emma/model/chat_room.dart';
import 'package:emma/model/massage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class EmmaPendingToolAction {
  final String id;
  final String toolName;
  final String moduleKey;

  final int sessionLocalId;
  final int assistantMessageLocalId;

  final String clientActionId;
  final String? localEntityId;
  final String? entityType;

  final Map<String, dynamic> arguments;
  final List<Map<String, dynamic>> optimisticBlocks;

  final String status;
  final int attemptCount;
  final String? lastError;
  final Map<String, dynamic>? backendResult;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? nextRetryAt;

  const EmmaPendingToolAction({
    required this.id,
    required this.toolName,
    required this.moduleKey,
    required this.sessionLocalId,
    required this.assistantMessageLocalId,
    required this.clientActionId,
    required this.localEntityId,
    required this.entityType,
    required this.arguments,
    required this.optimisticBlocks,
    required this.status,
    required this.attemptCount,
    required this.lastError,
    required this.backendResult,
    required this.createdAt,
    required this.updatedAt,
    required this.nextRetryAt,
  });

  EmmaPendingToolAction copyWith({
    String? status,
    int? attemptCount,
    String? lastError,
    Map<String, dynamic>? backendResult,
    DateTime? updatedAt,
    DateTime? nextRetryAt,
  }) {
    return EmmaPendingToolAction(
      id: id,
      toolName: toolName,
      moduleKey: moduleKey,
      sessionLocalId: sessionLocalId,
      assistantMessageLocalId: assistantMessageLocalId,
      clientActionId: clientActionId,
      localEntityId: localEntityId,
      entityType: entityType,
      arguments: arguments,
      optimisticBlocks: optimisticBlocks,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      backendResult: backendResult ?? this.backendResult,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'tool_name': toolName,
      'module_key': moduleKey,
      'session_local_id': sessionLocalId,
      'assistant_message_local_id': assistantMessageLocalId,
      'client_action_id': clientActionId,
      'local_entity_id': localEntityId,
      'entity_type': entityType,
      'arguments_json': jsonEncode(arguments),
      'optimistic_blocks_json': jsonEncode(optimisticBlocks),
      'status': status,
      'attempt_count': attemptCount,
      'last_error': lastError,
      'backend_result_json':
          backendResult == null ? null : jsonEncode(backendResult),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'next_retry_at': nextRetryAt?.toIso8601String(),
    };
  }

  factory EmmaPendingToolAction.fromDbMap(Map<String, Object?> map) {
    return EmmaPendingToolAction(
      id: (map['id'] ?? '').toString(),
      toolName: (map['tool_name'] ?? '').toString(),
      moduleKey: (map['module_key'] ?? '').toString(),
      sessionLocalId:
          int.tryParse((map['session_local_id'] ?? '').toString()) ?? 0,
      assistantMessageLocalId: int.tryParse(
            (map['assistant_message_local_id'] ?? '').toString(),
          ) ??
          0,
      clientActionId: (map['client_action_id'] ?? '').toString(),
      localEntityId: _nullableText(map['local_entity_id']),
      entityType: _nullableText(map['entity_type']),
      arguments: _safeJsonMap(map['arguments_json']),
      optimisticBlocks: _safeJsonListOfMaps(map['optimistic_blocks_json']),
      status: (map['status'] ?? 'pending').toString(),
      attemptCount: int.tryParse((map['attempt_count'] ?? '').toString()) ?? 0,
      lastError: _nullableText(map['last_error']),
      backendResult: map['backend_result_json'] == null
          ? null
          : _safeJsonMap(map['backend_result_json']),
      createdAt: _safeDate(map['created_at']),
      updatedAt: _safeDate(map['updated_at']),
      nextRetryAt: _safeNullableDate(map['next_retry_at']),
    );
  }

  static String? _nullableText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime _safeDate(dynamic value) {
    final parsed = DateTime.tryParse((value ?? '').toString());
    return parsed ?? DateTime.now();
  }

  static DateTime? _safeNullableDate(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }

  static Map<String, dynamic> _safeJsonMap(dynamic value) {
    try {
      if (value == null) return <String, dynamic>{};

      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);

      final decoded = jsonDecode(value.toString());
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _safeJsonListOfMaps(dynamic value) {
    try {
      if (value == null) return <Map<String, dynamic>>[];

      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      }

      final decoded = jsonDecode(value.toString());

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      }
    } catch (_) {}

    return <Map<String, dynamic>>[];
  }
}

class EmmaLocalDb {
  EmmaLocalDb._();

  static final EmmaLocalDb instance = EmmaLocalDb._();

  static const int _dbVersion = 3;

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'emma_offline_sync.db');

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createChatTables(db);
        await _createLocalModelTables(db);
        await _createPendingToolActionTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createLocalModelTables(db);
        }

        if (oldVersion < 3) {
          await _createPendingToolActionTables(db);
        }
      },
      onOpen: (db) async {
        // sqflite_darwin has a known bug where PRAGMA statements can throw a
        // DatabaseException with "not an error" (SqfliteDarwinDatabase
        // Code=0) on iOS even though the pragma applied successfully. Left
        // unguarded, that exception propagates out of openDatabase(), so
        // `_db` never gets cached and every local DB read/write downstream
        // (including a just-created chat room's local persist) throws too.
        // These pragmas are pure perf tuning — safe to ignore on failure.
        for (final pragma in const [
          'PRAGMA journal_mode=WAL',
          'PRAGMA synchronous=NORMAL',
          'PRAGMA cache_size=-2048',
        ]) {
          try {
            await db.execute(pragma);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Emma: local db pragma failed ($pragma): $e');
            }
          }
        }

        // If the app was killed while syncing, make these actions retryable.
        await _resetStuckPendingToolActions(db);
      },
    );

    _db = db;
    return db;
  }

  static Future<void> _createChatTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS emma_sessions (
        local_id INTEGER PRIMARY KEY,
        server_id INTEGER,
        client_uuid TEXT NOT NULL,
        title TEXT,
        created_at TEXT NOT NULL,
        last_activity_at TEXT NOT NULL,
        json TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_emma_sessions_client_uuid
      ON emma_sessions(client_uuid)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_emma_sessions_server_id
      ON emma_sessions(server_id)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS emma_messages (
        local_id INTEGER PRIMARY KEY,
        server_id INTEGER,
        client_uuid TEXT NOT NULL,
        session_local_id INTEGER NOT NULL,
        session_server_id INTEGER,
        session_client_uuid TEXT NOT NULL,
        role TEXT NOT NULL,
        kind TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        json TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_emma_messages_client_uuid
      ON emma_messages(client_uuid)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_emma_messages_session_local_id
      ON emma_messages(session_local_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_emma_messages_server_id
      ON emma_messages(server_id)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS emma_sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  static Future<void> _createLocalModelTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS emma_local_models (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        model_id TEXT NOT NULL,
        name TEXT NOT NULL,
        task_bucket TEXT NOT NULL,
        file_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        local_path TEXT NOT NULL,
        size_bytes INTEGER,
        sha256 TEXT,
        source_type TEXT,
        download_type TEXT,
        is_active INTEGER NOT NULL DEFAULT 0,
        installed_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        json TEXT NOT NULL,
        UNIQUE(model_id, file_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_emma_local_models_bucket
      ON emma_local_models(task_bucket)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_emma_local_models_active_bucket
      ON emma_local_models(task_bucket, is_active)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_emma_local_models_model_file
      ON emma_local_models(model_id, file_id)
    ''');
  }

  static Future<void> _createPendingToolActionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS emma_pending_tool_actions (
        id TEXT PRIMARY KEY,
        tool_name TEXT NOT NULL,
        module_key TEXT NOT NULL DEFAULT '',
        session_local_id INTEGER NOT NULL,
        assistant_message_local_id INTEGER NOT NULL,
        client_action_id TEXT NOT NULL,
        local_entity_id TEXT,
        entity_type TEXT,
        arguments_json TEXT NOT NULL DEFAULT '{}',
        optimistic_blocks_json TEXT NOT NULL DEFAULT '[]',
        status TEXT NOT NULL DEFAULT 'pending',
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        backend_result_json TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        next_retry_at TEXT
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_emma_pending_tool_actions_client_action
      ON emma_pending_tool_actions(client_action_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_emma_pending_tool_actions_status
      ON emma_pending_tool_actions(status, next_retry_at)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_emma_pending_tool_actions_message
      ON emma_pending_tool_actions(session_local_id, assistant_message_local_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_emma_pending_tool_actions_tool
      ON emma_pending_tool_actions(tool_name, module_key)
    ''');
  }

  static Future<void> _resetStuckPendingToolActions(Database db) async {
    await db.update(
      'emma_pending_tool_actions',
      {
        'status': 'failed_retryable',
        'updated_at': DateTime.now().toIso8601String(),
        'next_retry_at': null,
        'last_error': 'App closed while syncing. Retrying.',
      },
      where: 'status = ?',
      whereArgs: ['syncing'],
    );
  }

  Future<String?> getMeta(String key) async {
    final db = await database;
    final rows = await db.query(
      'emma_sync_meta',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first['value']?.toString();
  }

  Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.insert(
      'emma_sync_meta',
      {
        'key': key,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertRoom(
    ChatRoom room, {
    required String clientUuid,
    String syncStatus = 'synced',
  }) async {
    final db = await database;

    final serverId = room.id > 0 ? room.id : null;
    final localId = room.id;

    final createdAt = room.createdAt ?? DateTime.now().toIso8601String();
    final lastActivityAt =
        room.lastActivityAt ?? room.createdAt ?? DateTime.now().toIso8601String();

    await db.insert(
      'emma_sessions',
      {
        'local_id': localId,
        'server_id': serverId,
        'client_uuid': clientUuid,
        'title': room.title ?? 'New chat',
        'created_at': createdAt,
        'last_activity_at': lastActivityAt,
        'json': jsonEncode(_roomToLocalJson(room, clientUuid: clientUuid)),
        'sync_status': syncStatus,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatRoom>> getRooms() async {
    final db = await database;

    final rows = await db.query(
      'emma_sessions',
      orderBy: 'last_activity_at DESC',
    );

    return rows.map((row) {
      final raw = jsonDecode(row['json'].toString());

      if (raw is Map<String, dynamic>) {
        return ChatRoom.fromJson(raw);
      }

      return ChatRoom.fromJson(Map<String, dynamic>.from(raw as Map));
    }).toList();
  }

  Future<void> upsertMessage(
    ChatMessageDto message, {
    required String clientUuid,
    required int sessionLocalId,
    required String sessionClientUuid,
    String syncStatus = 'synced',
  }) async {
    final db = await database;

    final serverId = message.id > 0 ? message.id : null;
    final sessionServerId = message.sessionId > 0 ? message.sessionId : null;

    await db.insert(
      'emma_messages',
      {
        'local_id': message.id,
        'server_id': serverId,
        'client_uuid': clientUuid,
        'session_local_id': sessionLocalId,
        'session_server_id': sessionServerId,
        'session_client_uuid': sessionClientUuid,
        'role': message.role,
        'kind': message.kind,
        'content': message.content,
        'created_at': message.createdAt.toIso8601String(),
        'json': jsonEncode(_messageToLocalJson(message, clientUuid: clientUuid)),
        'sync_status': syncStatus,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.update(
      'emma_sessions',
      {
        'last_activity_at': message.createdAt.toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [sessionLocalId],
    );
  }

  Future<List<ChatMessageDto>> getMessagesForSession(int sessionId) async {
    final db = await database;

    final rows = await db.query(
      'emma_messages',
      where: 'session_local_id = ? OR session_server_id = ?',
      whereArgs: [sessionId, sessionId],
      orderBy: 'created_at ASC',
    );

    return rows.map((row) {
      final raw = jsonDecode(row['json'].toString());

      if (raw is Map<String, dynamic>) {
        return ChatMessageDto.fromJson(raw);
      }

      return ChatMessageDto.fromJson(Map<String, dynamic>.from(raw as Map));
    }).toList();
  }

  Future<List<Map<String, dynamic>>> pendingSessions() async {
    final db = await database;
    return db.query(
      'emma_sessions',
      where: 'sync_status != ?',
      whereArgs: ['synced'],
    );
  }

  Future<List<Map<String, dynamic>>> pendingMessages() async {
    final db = await database;
    return db.query(
      'emma_messages',
      where: 'sync_status != ?',
      whereArgs: ['synced'],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> applySessionIdMap(Map<String, dynamic> map) async {
    final db = await database;

    for (final entry in map.entries) {
      final clientUuid = entry.key;
      final serverId = int.tryParse(entry.value.toString());
      if (serverId == null) continue;

      final rows = await db.query(
        'emma_sessions',
        where: 'client_uuid = ?',
        whereArgs: [clientUuid],
        limit: 1,
      );

      if (rows.isEmpty) continue;

      final oldLocalId = rows.first['local_id'] as int;

      await db.update(
        'emma_sessions',
        {
          'local_id': serverId,
          'server_id': serverId,
          'sync_status': 'synced',
        },
        where: 'client_uuid = ?',
        whereArgs: [clientUuid],
      );

      await db.update(
        'emma_messages',
        {
          'session_local_id': serverId,
          'session_server_id': serverId,
        },
        where: 'session_local_id = ?',
        whereArgs: [oldLocalId],
      );
    }
  }

  Future<void> applyMessageIdMap(Map<String, dynamic> map) async {
    final db = await database;

    for (final entry in map.entries) {
      final clientUuid = entry.key;
      final serverId = int.tryParse(entry.value.toString());
      if (serverId == null) continue;

      await db.update(
        'emma_messages',
        {
          'local_id': serverId,
          'server_id': serverId,
          'sync_status': 'synced',
        },
        where: 'client_uuid = ?',
        whereArgs: [clientUuid],
      );
    }
  }

  Future<void> upsertServerRoomJson(Map<String, dynamic> json) async {
    final room = ChatRoom.fromJson(json);
    final clientUuid =
        (json['client_uuid'] ?? 'server_session_${room.id}').toString();

    await upsertRoom(
      room,
      clientUuid: clientUuid,
      syncStatus: 'synced',
    );
  }

  Future<void> upsertServerMessageJson(Map<String, dynamic> json) async {
    final message = ChatMessageDto.fromJson(json);
    final clientUuid =
        (json['client_uuid'] ?? 'server_message_${message.id}').toString();

    final sessionIdRaw = json['session'];
    final sessionId = sessionIdRaw is int
        ? sessionIdRaw
        : int.tryParse(sessionIdRaw.toString()) ?? message.sessionId;

    await upsertMessage(
      message.copyWith(sessionId: sessionId),
      clientUuid: clientUuid,
      sessionLocalId: sessionId,
      sessionClientUuid: 'server_session_$sessionId',
      syncStatus: 'synced',
    );
  }

  Future<void> upsertPendingToolAction(
    EmmaPendingToolAction action,
  ) async {
    final db = await database;

    await db.insert(
      'emma_pending_tool_actions',
      action.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<EmmaPendingToolAction?> getPendingToolActionById(String id) async {
    final db = await database;

    final rows = await db.query(
      'emma_pending_tool_actions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return EmmaPendingToolAction.fromDbMap(rows.first);
  }

  Future<List<EmmaPendingToolAction>> getPendingToolActionsReady({
    int limit = 25,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final rows = await db.query(
      'emma_pending_tool_actions',
      where: '''
        status IN (?, ?)
        AND (next_retry_at IS NULL OR next_retry_at <= ?)
      ''',
      whereArgs: [
        'pending',
        'failed_retryable',
        now,
      ],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows
        .map((row) => EmmaPendingToolAction.fromDbMap(row))
        .toList(growable: false);
  }

  Future<List<EmmaPendingToolAction>> getPendingToolActionsForMessage({
    required int sessionLocalId,
    required int assistantMessageLocalId,
  }) async {
    final db = await database;

    final rows = await db.query(
      'emma_pending_tool_actions',
      where: 'session_local_id = ? AND assistant_message_local_id = ?',
      whereArgs: [sessionLocalId, assistantMessageLocalId],
      orderBy: 'created_at ASC',
    );

    return rows
        .map((row) => EmmaPendingToolAction.fromDbMap(row))
        .toList(growable: false);
  }

  Future<void> markPendingToolActionSyncing(String id) async {
    final db = await database;

    await db.update(
      'emma_pending_tool_actions',
      {
        'status': 'syncing',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markPendingToolActionSynced({
    required String id,
    required Map<String, dynamic> backendResult,
  }) async {
    final db = await database;

    await db.update(
      'emma_pending_tool_actions',
      {
        'status': 'synced',
        'backend_result_json': jsonEncode(backendResult),
        'last_error': null,
        'updated_at': DateTime.now().toIso8601String(),
        'next_retry_at': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markPendingToolActionFailed({
    required String id,
    required String error,
    required int attemptCount,
    bool retryable = true,
  }) async {
    final db = await database;

    final now = DateTime.now();

    int delayMinutes;
    if (attemptCount <= 1) {
      delayMinutes = 1;
    } else if (attemptCount == 2) {
      delayMinutes = 3;
    } else if (attemptCount == 3) {
      delayMinutes = 10;
    } else if (attemptCount == 4) {
      delayMinutes = 30;
    } else {
      delayMinutes = 60;
    }

    await db.update(
      'emma_pending_tool_actions',
      {
        'status': retryable ? 'failed_retryable' : 'failed',
        'attempt_count': attemptCount,
        'last_error': error,
        'updated_at': now.toIso8601String(),
        'next_retry_at': retryable
            ? now.add(Duration(minutes: delayMinutes)).toIso8601String()
            : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePendingToolAction(String id) async {
    final db = await database;

    await db.delete(
      'emma_pending_tool_actions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSyncedPendingToolActions({
    int olderThanHours = 24,
  }) async {
    final db = await database;

    final cutoff = DateTime.now()
        .subtract(Duration(hours: olderThanHours))
        .toIso8601String();

    await db.delete(
      'emma_pending_tool_actions',
      where: 'status = ? AND updated_at <= ?',
      whereArgs: ['synced', cutoff],
    );
  }

  Future<int> countPendingToolActions() async {
    final db = await database;

    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM emma_pending_tool_actions
      WHERE status IN (?, ?, ?)
    ''', [
      'pending',
      'failed_retryable',
      'syncing',
    ]);

    if (rows.isEmpty) return 0;

    final value = rows.first['count'];
    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> upsertInstalledModel(
    EmmaLocalInstalledModel model, {
    bool? isActive,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      final active = isActive ?? model.isActive;

      if (active) {
        await txn.update(
          'emma_local_models',
          {'is_active': 0},
          where: 'task_bucket = ?',
          whereArgs: [model.taskBucket],
        );
      }

      final json = model.copyWith(isActive: active).toJson();

      await txn.insert(
        'emma_local_models',
        {
          'model_id': model.modelId,
          'name': model.name,
          'task_bucket': model.taskBucket,
          'file_id': model.fileId,
          'file_name': model.fileName,
          'local_path': model.localPath,
          'size_bytes': model.sizeBytes,
          'sha256': model.sha256,
          'source_type': model.sourceType,
          'download_type': model.downloadType,
          'is_active': active ? 1 : 0,
          'installed_at': model.installedAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'json': jsonEncode(json),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> replaceInstalledModels(
    List<EmmaLocalInstalledModel> models,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('emma_local_models');

      for (final model in models) {
        final json = model.toJson();

        await txn.insert(
          'emma_local_models',
          {
            'model_id': model.modelId,
            'name': model.name,
            'task_bucket': model.taskBucket,
            'file_id': model.fileId,
            'file_name': model.fileName,
            'local_path': model.localPath,
            'size_bytes': model.sizeBytes,
            'sha256': model.sha256,
            'source_type': model.sourceType,
            'download_type': model.downloadType,
            'is_active': model.isActive ? 1 : 0,
            'installed_at': model.installedAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'json': jsonEncode(json),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<EmmaLocalInstalledModel>> getInstalledModels({
    String? taskBucket,
  }) async {
    final db = await database;

    final rows = await db.query(
      'emma_local_models',
      where: taskBucket == null ? null : 'task_bucket = ?',
      whereArgs: taskBucket == null ? null : [taskBucket],
      orderBy: 'task_bucket ASC, is_active DESC, name COLLATE NOCASE ASC',
    );

    return rows.map(_installedModelFromRow).toList();
  }

  Future<EmmaLocalInstalledModel?> getActiveInstalledModel(
    String taskBucket,
  ) async {
    final db = await database;

    final rows = await db.query(
      'emma_local_models',
      where: 'task_bucket = ? AND is_active = 1',
      whereArgs: [taskBucket],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _installedModelFromRow(rows.first);
  }

  Future<void> setActiveInstalledModel({
    required String taskBucket,
    required String modelId,
    required String fileId,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.update(
        'emma_local_models',
        {'is_active': 0},
        where: 'task_bucket = ?',
        whereArgs: [taskBucket],
      );

      await txn.update(
        'emma_local_models',
        {
          'is_active': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'task_bucket = ? AND model_id = ? AND file_id = ?',
        whereArgs: [taskBucket, modelId, fileId],
      );

      final rows = await txn.query(
        'emma_local_models',
        where: 'task_bucket = ? AND model_id = ? AND file_id = ?',
        whereArgs: [taskBucket, modelId, fileId],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final row = rows.first;
        final json = _safeJsonMap(row['json']);
        json['is_active'] = true;

        await txn.update(
          'emma_local_models',
          {
            'json': jsonEncode(json),
          },
          where: 'task_bucket = ? AND model_id = ? AND file_id = ?',
          whereArgs: [taskBucket, modelId, fileId],
        );
      }
    });
  }

  Future<void> deleteInstalledModelRow({
    required String modelId,
    String? fileId,
  }) async {
    final db = await database;

    if (fileId == null || fileId.trim().isEmpty) {
      await db.delete(
        'emma_local_models',
        where: 'model_id = ?',
        whereArgs: [modelId],
      );
      return;
    }

    await db.delete(
      'emma_local_models',
      where: 'model_id = ? AND file_id = ?',
      whereArgs: [modelId, fileId],
    );
  }

  Future<void> clearInstalledModels() async {
    final db = await database;
    await db.delete('emma_local_models');
  }

  EmmaLocalInstalledModel _installedModelFromRow(Map<String, Object?> row) {
    final json = _safeJsonMap(row['json']);

    if (json.isNotEmpty) {
      json['is_active'] = row['is_active'] == 1;
      return EmmaLocalInstalledModel.fromJson(json);
    }

    return EmmaLocalInstalledModel(
      modelId: row['model_id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      taskBucket: row['task_bucket']?.toString() ?? 'llm',
      fileId: row['file_id']?.toString() ?? '',
      fileName: row['file_name']?.toString() ?? '',
      localPath: row['local_path']?.toString() ?? '',
      sizeBytes: row['size_bytes'] is int ? row['size_bytes'] as int : null,
      sha256: row['sha256']?.toString() ?? '',
      installedAt: DateTime.tryParse(row['installed_at']?.toString() ?? '') ??
          DateTime.now(),
      sourceType: row['source_type']?.toString() ?? '',
      downloadType: row['download_type']?.toString() ?? '',
      isActive: row['is_active'] == 1,
    );
  }

  Map<String, dynamic> _roomToLocalJson(
    ChatRoom room, {
    required String clientUuid,
  }) {
    return {
      'id': room.id,
      'client_uuid': clientUuid,
      'title': room.title,
      'created_at': room.createdAt,
      'last_activity_at': room.lastActivityAt,
    };
  }

  Map<String, dynamic> _messageToLocalJson(
    ChatMessageDto message, {
    required String clientUuid,
  }) {
    return {
      'id': message.id,
      'client_uuid': clientUuid,
      'session': message.sessionId,
      'role': message.role,
      'kind': message.kind,
      'content': message.content,
      'meta': message.meta,
      'likes_count': message.likesCount,
      'dislikes_count': message.dislikesCount,
      'created_at': message.createdAt.toIso8601String(),
      'is_seen': message.isSeen,
      'seen_at': message.seenAt?.toIso8601String(),
    };
  }

  static Map<String, dynamic> _safeJsonMap(dynamic value) {
    try {
      if (value == null) return <String, dynamic>{};

      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);

      final decoded = jsonDecode(value.toString());
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    return <String, dynamic>{};
  }
}