import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class MapLayerCacheEntry {
  final String key;
  final Map<String, dynamic> data;
  final DateTime savedAt;
  final DateTime lastAccessedAt;
  final bool isExpired;
  final int approxBytes;

  const MapLayerCacheEntry({
    required this.key,
    required this.data,
    required this.savedAt,
    required this.lastAccessedAt,
    required this.isExpired,
    required this.approxBytes,
  });
}

class MapLayerCacheStats {
  final int entries;
  final int approxBytes;
  final DateTime? oldestSavedAt;
  final DateTime? newestSavedAt;

  const MapLayerCacheStats({
    required this.entries,
    required this.approxBytes,
    required this.oldestSavedAt,
    required this.newestSavedAt,
  });
}

class MapLayerCacheMetadata {
  final int? zoomBucket;
  final double? west;
  final double? south;
  final double? east;
  final double? north;

  const MapLayerCacheMetadata({
    this.zoomBucket,
    this.west,
    this.south,
    this.east,
    this.north,
  });

  bool get hasProjectedBounds {
    return zoomBucket != null &&
        west != null &&
        south != null &&
        east != null &&
        north != null;
  }
}

class MapLayerLocalCache {
  static const String _dbName = 'portal_map_layer_cache.sqlite';
  static const int _dbVersion = 1;
  static const String _table = 'map_layer_cache_entries';

  /// Legacy SharedPreferences cache prefixes.
  ///
  /// Old cache used SharedPreferences. We keep these prefixes only for cleanup.
  static const String _legacyEntryPrefix = 'map_layer_cache_entry__';
  static const String _legacyIndexPrefix = 'map_layer_cache_index__';

  static Future<Database>? _databaseFuture;

  final String namespace;
  final Duration ttl;

  /// Entries older than [ttl] are stale, but can still be used as fallback.
  /// Entries older than [maxStaleTtl] are removed permanently.
  final Duration maxStaleTtl;

  final int maxEntries;

  int _writesSinceLastPrune = 0;
  static const int _pruneEveryNWrites = 20;

  MapLayerLocalCache._({
    required this.namespace,
    required this.ttl,
    required this.maxStaleTtl,
    required this.maxEntries,
  });

  static Future<MapLayerLocalCache> create({
    required String namespace,
    Duration ttl = const Duration(days: 30),
    Duration? maxStaleTtl,
    int maxEntries = 160,
  }) async {
    final cache = MapLayerLocalCache._(
      namespace: namespace,
      ttl: ttl,
      maxStaleTtl: maxStaleTtl ?? _defaultMaxStaleTtl(ttl),
      maxEntries: maxEntries,
    );

    await _database();
    await cache._prune();

    return cache;
  }

  static Duration _defaultMaxStaleTtl(Duration ttl) {
    final ttlMs = ttl.inMilliseconds <= 0
        ? const Duration(days: 30).inMilliseconds
        : ttl.inMilliseconds;

    final maxMs = math.max(
      ttlMs * 4,
      const Duration(days: 90).inMilliseconds,
    );

    return Duration(milliseconds: maxMs);
  }

  static Future<Database> _database() {
    _databaseFuture ??= _openDatabase();
    return _databaseFuture!;
  }

  static Future<Database> _openDatabase() async {
    final dbDir = await getDatabasesPath();
    await Directory(dbDir).create(recursive: true);
    final dbPath = p.join(dbDir, _dbName);

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onOpen: (db) async {
        // journal_mode=WAL returns the resulting mode as a row; on
        // sqflite_darwin, running it via execute() (which discards results)
        // trips a native bug that throws a bogus "not an error" exception.
        await db.rawQuery('PRAGMA journal_mode=WAL');
        await db.execute('PRAGMA synchronous=NORMAL');
        await db.execute('PRAGMA cache_size=-4096');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            namespace TEXT NOT NULL,
            cache_key TEXT NOT NULL,
            zoom_bucket INTEGER,
            west REAL,
            south REAL,
            east REAL,
            north REAL,
            saved_at_ms INTEGER NOT NULL,
            last_accessed_at_ms INTEGER NOT NULL,
            approx_bytes INTEGER NOT NULL,
            data_json TEXT NOT NULL,
            PRIMARY KEY (namespace, cache_key)
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_map_cache_lookup
          ON $_table (
            namespace,
            zoom_bucket,
            west,
            south,
            east,
            north,
            saved_at_ms
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_map_cache_lru
          ON $_table (
            namespace,
            last_accessed_at_ms
          )
        ''');
      },
    );
  }

  Future<List<String>> keys() async {
    final db = await _database();

    final rows = await db.query(
      _table,
      columns: ['cache_key'],
      where: 'namespace = ?',
      whereArgs: [namespace],
      orderBy: 'last_accessed_at_ms DESC',
    );

    return rows
        .map((row) => row['cache_key']?.toString())
        .whereType<String>()
        .toList();
  }

  Future<MapLayerCacheEntry?> read(
    String key, {
    bool touch = false,
  }) async {
    final db = await _database();

    final rows = await db.query(
      _table,
      where: 'namespace = ? AND cache_key = ?',
      whereArgs: [namespace, key],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final entry = _entryFromRow(rows.first);

    if (_isHardExpired(entry.savedAt)) {
      await remove(key);
      return null;
    }

    if (touch) {
      await _touch(db, key);
    }

    return entry;
  }

  Future<MapLayerCacheEntry?> findContainingBounds({
    required int zoomBucket,
    required double west,
    required double south,
    required double east,
    required double north,
    bool allowExpired = true,
    bool touch = true,
  }) async {
    final db = await _database();

    final freshCutoffMs =
        DateTime.now().subtract(ttl).millisecondsSinceEpoch;

    final fresh = await _queryContainingBounds(
      db: db,
      zoomBucket: zoomBucket,
      west: west,
      south: south,
      east: east,
      north: north,
      savedAfterMs: freshCutoffMs,
    );

    if (fresh != null) {
      if (touch) {
        await _touch(db, fresh.key);
      }
      return fresh;
    }

    if (!allowExpired) return null;

    final staleCutoffMs =
        DateTime.now().subtract(maxStaleTtl).millisecondsSinceEpoch;

    final stale = await _queryContainingBounds(
      db: db,
      zoomBucket: zoomBucket,
      west: west,
      south: south,
      east: east,
      north: north,
      savedAfterMs: staleCutoffMs,
    );

    if (stale != null && touch) {
      await _touch(db, stale.key);
    }

    return stale;
  }

  Future<MapLayerCacheEntry?> _queryContainingBounds({
    required Database db,
    required int zoomBucket,
    required double west,
    required double south,
    required double east,
    required double north,
    required int savedAfterMs,
  }) async {
    final rows = await db.query(
      _table,
      where: '''
        namespace = ?
        AND zoom_bucket = ?
        AND west <= ?
        AND south <= ?
        AND east >= ?
        AND north >= ?
        AND saved_at_ms >= ?
      ''',
      whereArgs: [
        namespace,
        zoomBucket,
        west,
        south,
        east,
        north,
        savedAfterMs,
      ],
      orderBy: '''
        ((east - west) * (north - south)) ASC,
        last_accessed_at_ms DESC
      ''',
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return _entryFromRow(rows.first);
  }

  Future<void> write(
    String key,
    Map<String, dynamic> data, {
    MapLayerCacheMetadata? metadata,
  }) async {
    final db = await _database();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final dataJson = jsonEncode(data);
    final approxBytes = utf8.encode(dataJson).length;

    await db.insert(
      _table,
      {
        'namespace': namespace,
        'cache_key': key,
        'zoom_bucket': metadata?.zoomBucket,
        'west': metadata?.west,
        'south': metadata?.south,
        'east': metadata?.east,
        'north': metadata?.north,
        'saved_at_ms': nowMs,
        'last_accessed_at_ms': nowMs,
        'approx_bytes': approxBytes,
        'data_json': dataJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _writesSinceLastPrune++;
    if (_writesSinceLastPrune >= _pruneEveryNWrites) {
      _writesSinceLastPrune = 0;
      await _prune();
    }
  }

  Future<void> remove(String key) async {
    final db = await _database();

    await db.delete(
      _table,
      where: 'namespace = ? AND cache_key = ?',
      whereArgs: [namespace, key],
    );
  }

  Future<void> clear() async {
    final db = await _database();

    await db.delete(
      _table,
      where: 'namespace = ?',
      whereArgs: [namespace],
    );
  }

  Future<MapLayerCacheStats> stats() async {
    await _prune();

    final db = await _database();

    final rows = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS entries,
        COALESCE(SUM(approx_bytes), 0) AS approx_bytes,
        MIN(saved_at_ms) AS oldest_saved_at_ms,
        MAX(saved_at_ms) AS newest_saved_at_ms
      FROM $_table
      WHERE namespace = ?
      ''',
      [namespace],
    );

    final row = rows.first;

    final entries = _rowInt(row, 'entries') ?? 0;
    final approxBytes = _rowInt(row, 'approx_bytes') ?? 0;
    final oldestMs = _rowInt(row, 'oldest_saved_at_ms');
    final newestMs = _rowInt(row, 'newest_saved_at_ms');

    return MapLayerCacheStats(
      entries: entries,
      approxBytes: approxBytes,
      oldestSavedAt: oldestMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(oldestMs),
      newestSavedAt: newestMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(newestMs),
    );
  }

  Future<void> _touch(Database db, String key) async {
    await db.update(
      _table,
      {
        'last_accessed_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'namespace = ? AND cache_key = ?',
      whereArgs: [namespace, key],
    );
  }

  MapLayerCacheEntry _entryFromRow(Map<String, Object?> row) {
    final key = row['cache_key']?.toString() ?? '';

    final savedAtMs = _rowInt(row, 'saved_at_ms') ?? 0;
    final lastAccessedAtMs =
        _rowInt(row, 'last_accessed_at_ms') ?? savedAtMs;

    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
    final lastAccessedAt =
        DateTime.fromMillisecondsSinceEpoch(lastAccessedAtMs);

    final rawJson = row['data_json']?.toString() ?? '{}';

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(rawJson);
      data = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      data = <String, dynamic>{};
    }

    return MapLayerCacheEntry(
      key: key,
      data: data,
      savedAt: savedAt,
      lastAccessedAt: lastAccessedAt,
      isExpired: DateTime.now().difference(savedAt) > ttl,
      approxBytes: _rowInt(row, 'approx_bytes') ?? utf8.encode(rawJson).length,
    );
  }

  bool _isHardExpired(DateTime savedAt) {
    return DateTime.now().difference(savedAt) > maxStaleTtl;
  }

  Future<void> _prune() async {
    final db = await _database();

    final hardCutoffMs =
        DateTime.now().subtract(maxStaleTtl).millisecondsSinceEpoch;

    // Single query: delete hard-expired AND LRU overflow in one shot.
    if (maxEntries > 0) {
      await db.rawDelete(
        '''
        DELETE FROM $_table
        WHERE namespace = ?
          AND (
            saved_at_ms < ?
            OR cache_key NOT IN (
              SELECT cache_key FROM $_table
              WHERE namespace = ?
              ORDER BY last_accessed_at_ms DESC
              LIMIT ?
            )
          )
        ''',
        [namespace, hardCutoffMs, namespace, maxEntries],
      );
    } else {
      await db.delete(
        _table,
        where: 'namespace = ? AND saved_at_ms < ?',
        whereArgs: [namespace, hardCutoffMs],
      );
    }
  }

  static int? _rowInt(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Future<void> clearAllMapCaches() async {
    final db = await _database();
    await db.delete(_table);
    await clearLegacySharedPreferencesMapCaches();
  }

  static const String _legacyMigrationDoneKey =
      'map_layer_cache_legacy_prefs_cleaned';

  static Future<void> clearLegacySharedPreferencesMapCaches() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_legacyMigrationDoneKey) == true) return;

    final keys = prefs.getKeys().toList();

    for (final key in keys) {
      if (key.startsWith(_legacyEntryPrefix) ||
          key.startsWith(_legacyIndexPrefix)) {
        await prefs.remove(key);
      }
    }

    await prefs.setBool(_legacyMigrationDoneKey, true);
  }

  static Future<void> closeForTests() async {
    final db = await _databaseFuture;
    await db?.close();
    _databaseFuture = null;
  }
}