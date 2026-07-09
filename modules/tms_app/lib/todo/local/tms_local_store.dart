import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tms_app/todo/local/tms_pending_op.dart';
import 'package:tms_app/todo/models/board_details_model.dart';
import 'package:tms_app/todo/models/board_progress_model.dart';
import 'package:tms_app/todo/models/get_user_board_model.dart';
import 'package:tms_app/todo/models/tasks_model.dart';

final tmsLocalStoreProvider = Provider<TmsLocalStore>((ref) {
  return TmsLocalStore.instance;
});

class TmsLocalStore {
  TmsLocalStore._();

  static final TmsLocalStore instance = TmsLocalStore._();

  bool _initialized = false;

  static const _boardsBoxName = 'tms_boards_v1';
  static const _boardDetailsBoxName = 'tms_board_details_v1';
  static const _tasksBoxName = 'tms_tasks_v1';
  static const _searchCacheBoxName = 'tms_search_cache_v1';
  static const _syncMetaBoxName = 'tms_sync_meta_v1';
  static const _pendingOpsBoxName = 'tms_pending_ops_v1';

  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox(_boardsBoxName),
      Hive.openBox(_boardDetailsBoxName),
      Hive.openBox(_tasksBoxName),
      Hive.openBox(_searchCacheBoxName),
      Hive.openBox(_syncMetaBoxName),
      Hive.openBox(_pendingOpsBoxName),
    ]);

    _initialized = true;
  }

  Box get _boardsBox => Hive.box(_boardsBoxName);
  Box get _boardDetailsBox => Hive.box(_boardDetailsBoxName);
  Box get _tasksBox => Hive.box(_tasksBoxName);
  Box get _searchCacheBox => Hive.box(_searchCacheBoxName);
  Box get _syncMetaBox => Hive.box(_syncMetaBoxName);
  Box get _pendingOpsBox => Hive.box(_pendingOpsBoxName);

  Future<void> saveBoards(List<BoardResults> boards) async {
    await init();

    await _boardsBox.put(
      'all',
      boards.map((e) => e.toJson()).toList(),
    );

    await _syncMetaBox.put(
      'boards:last_fetch',
      DateTime.now().toIso8601String(),
    );
  }

  List<BoardResults> getBoardsSync() {
    final raw = _boardsBox.get('all');
    if (raw is! List) return const <BoardResults>[];

    return raw
        .whereType<Map>()
        .map((e) => BoardResults.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveBoardDetails(BoardDetailsModel board) async {
    await init();

    final boardId = board.id;
    if (boardId != null) {
      final existingProjectTasks = getTasksForProjectSync(boardId);
      if (existingProjectTasks.isNotEmpty) {
        for (final task in existingProjectTasks) {
          final id = task.id;
          if (id == null) continue;
          await _tasksBox.delete('$id');
        }
      }
    }

    await _boardDetailsBox.put('${board.id}', board.toJson());

    final progresses = board.projectProgresses ?? const <ProjectProgresses>[];
    for (final progress in progresses) {
      final tasks = progress.tasks ?? const <Tasks>[];
      for (final task in tasks) {
        if (task.id == null) continue;
        await _tasksBox.put('${task.id}', task.toJson());
      }
    }

    if (boardId != null) {
      await clearSearchCacheForProject(boardId);
      await setLastCheck(
        'board:$boardId:last_check',
        DateTime.now(),
      );
    }
  }

  BoardDetailsModel? getBoardDetailsSync(int boardId) {
    final raw = _boardDetailsBox.get('$boardId');
    if (raw is! Map) return null;
    return BoardDetailsModel.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> upsertTasks(List<Tasks> tasks) async {
    await init();

    for (final task in tasks) {
      if (task.id == null) continue;
      await _tasksBox.put('${task.id}', task.toJson());
    }
  }

  Future<void> deleteTasks(List<int> ids) async {
    await init();

    for (final id in ids) {
      await _tasksBox.delete('$id');
    }

    for (final key in _searchCacheBox.keys.map((e) => e.toString()).toList()) {
      final raw = _searchCacheBox.get(key);
      if (raw is! Map) continue;

      final taskIds = (raw['task_ids'] as List?)
              ?.map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toList() ??
          <int>[];

      taskIds.removeWhere(ids.contains);

      await _searchCacheBox.put(key, {
        ...Map<String, dynamic>.from(raw),
        'task_ids': taskIds,
      });
    }
  }

  Tasks? getTaskByIdSync(int taskId) {
    final raw = _tasksBox.get('$taskId');
    if (raw is! Map) return null;
    return Tasks.fromJson(Map<String, dynamic>.from(raw));
  }

  List<Tasks> getAllTasksSync() {
    return _tasksBox.values
        .whereType<Map>()
        .map((e) => Tasks.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<Tasks> getTasksForProjectSync(int projectId) {
    final tasks = getAllTasksSync()
        .where((t) => t.projectId == projectId)
        .toList();

    tasks.sort(_compareTasks);
    return tasks;
  }

  List<Tasks> getTasksForProgressSync(int progressId) {
    final tasks = getAllTasksSync()
        .where((t) => t.progressId == progressId)
        .toList();

    tasks.sort(_compareTasks);
    return tasks;
  }

  int getLocalCountForProject(int projectId) {
    return getTasksForProjectSync(projectId).length;
  }

  DateTime? getOldestTaskTimestampForProject(int projectId) {
    final tasks = getTasksForProjectSync(projectId);
    DateTime? oldest;

    for (final task in tasks) {
      final dt = DateTime.tryParse(task.timestamp ?? '');
      if (dt == null) continue;
      if (oldest == null || dt.isBefore(oldest)) {
        oldest = dt;
      }
    }

    return oldest;
  }

  Future<void> rebuildBoardFromTaskBox(int boardId) async {
    await init();

    final board = getBoardDetailsSync(boardId);
    if (board == null) return;

    final updatedProgresses =
        (board.projectProgresses ?? const <ProjectProgresses>[])
            .map((progress) {
      final progressId = progress.id;
      if (progressId == null) return progress;

      final localTasks = getTasksForProgressSync(progressId);
      return progress.copyWith(tasks: localTasks);
    }).toList();

    final rebuilt = BoardDetailsModel(
      id: board.id,
      user: board.user,
      projectProgresses: updatedProgresses,
      name: board.name,
      timestamp: board.timestamp,
      updatedAt: board.updatedAt,
      version: board.version,
    );

    await _boardDetailsBox.put('$boardId', rebuilt.toJson());
  }

  String makeSearchKey({
    required int projectId,
    required Map<String, dynamic> filters,
    required String search,
  }) {
    final normalized = <String, dynamic>{
      'project_id': projectId,
      'search': search.trim(),
      ...filters,
    };

    final keys = normalized.keys.toList()..sort();
    final ordered = <String, dynamic>{};

    for (final key in keys) {
      ordered[key] = normalized[key];
    }

    return jsonEncode(ordered);
  }

  Future<void> saveSearchCache({
    required String key,
    required int projectId,
    required Map<String, dynamic> filters,
    required String search,
    required List<Tasks> tasks,
    required DateTime checkedAt,
  }) async {
    await init();
    await upsertTasks(tasks);

    await _searchCacheBox.put(key, {
      'project_id': projectId,
      'filters': filters,
      'search': search,
      'task_ids': tasks.map((e) => e.id).whereType<int>().toList(),
      'checked_at': checkedAt.toIso8601String(),
    });
  }

  List<Tasks> getSearchCacheSync(String key) {
    final raw = _searchCacheBox.get(key);
    if (raw is! Map) return const <Tasks>[];

    final ids = (raw['task_ids'] as List?)
            ?.map((e) => int.tryParse(e.toString()))
            .whereType<int>()
            .toList() ??
        <int>[];

    final tasks = <Tasks>[];
    for (final id in ids) {
      final taskRaw = _tasksBox.get('$id');
      if (taskRaw is! Map) continue;
      tasks.add(Tasks.fromJson(Map<String, dynamic>.from(taskRaw)));
    }

    tasks.sort(_compareTasks);
    return tasks;
  }

  Future<void> clearSearchCacheForProject(int projectId) async {
    await init();

    final keysToDelete = <String>[];

    for (final key in _searchCacheBox.keys.map((e) => e.toString())) {
      final raw = _searchCacheBox.get(key);
      if (raw is! Map) continue;

      final cache = Map<String, dynamic>.from(raw);
      final rawProjectId = cache['project_id'];

      final cachedProjectId = rawProjectId is int
          ? rawProjectId
          : int.tryParse('$rawProjectId');

      if (cachedProjectId == projectId) {
        keysToDelete.add(key);
      }
    }

    for (final key in keysToDelete) {
      await _searchCacheBox.delete(key);
      await _syncMetaBox.delete('search:$key');
    }
  }

  List<Tasks> searchLocalTasks({
    required int projectId,
    required Map<String, dynamic> filters,
    String search = '',
  }) {
    var tasks = getTasksForProjectSync(projectId);

    final nameFilter = (filters['name'] ?? '').toString().trim().toLowerCase();
    if (nameFilter.isNotEmpty) {
      tasks = tasks.where((task) {
        final name = (task.name ?? '').toLowerCase();
        final description = (task.description ?? '').toLowerCase();
        return name.contains(nameFilter) || description.contains(nameFilter);
      }).toList();
    }

    final assignedTo = filters['assigned_to'];
    if (assignedTo != null && '$assignedTo'.trim().isNotEmpty) {
      final assignedId = int.tryParse('$assignedTo');
      if (assignedId != null) {
        tasks = tasks.where((task) => task.assignedTo == assignedId).toList();
      }
    }

    final assignedToIn = _parseIntList(filters['assigned_to__in']);
    if (assignedToIn.isNotEmpty) {
      tasks = tasks.where((task) {
        final id = task.assignedTo;
        return id != null && assignedToIn.contains(id);
      }).toList();
    }

    final members = _parseIntList(filters['members']);
    if (members.isNotEmpty) {
      tasks = tasks.where((task) {
        final taskMembers = task.members ?? const <int>[];
        return taskMembers.any(members.contains);
      }).toList();
    }

    final labels = _parseIntList(filters['label']);
    if (labels.isNotEmpty) {
      tasks = tasks.where((task) {
        final taskLabels = task.labels ?? const <int>[];
        return taskLabels.any(labels.contains);
      }).toList();
    }

    final priority = (filters['priority'] ?? '').toString().trim();
    if (priority.isNotEmpty) {
      tasks = tasks.where((task) => task.priority == priority).toList();
    }

    final isCompleted = _parseBool(filters['is_completed']);
    if (isCompleted != null) {
      tasks = tasks
          .where((task) => (task.isCompleted ?? false) == isCompleted)
          .toList();
    }

    final tsGte = DateTime.tryParse('${filters['timestamp__gte'] ?? ''}');
    if (tsGte != null) {
      tasks = tasks.where((task) {
        final dt = DateTime.tryParse(task.timestamp ?? '');
        return dt != null && !dt.isBefore(tsGte);
      }).toList();
    }

    final tsLte = DateTime.tryParse('${filters['timestamp__lte'] ?? ''}');
    if (tsLte != null) {
      tasks = tasks.where((task) {
        final dt = DateTime.tryParse(task.timestamp ?? '');
        return dt != null && !dt.isAfter(tsLte);
      }).toList();
    }

    final dlGte = DateTime.tryParse('${filters['deadline__gte'] ?? ''}');
    if (dlGte != null) {
      tasks = tasks.where((task) {
        final dt = DateTime.tryParse(task.deadline ?? '');
        return dt != null && !dt.isBefore(dlGte);
      }).toList();
    }

    final dlLte = DateTime.tryParse('${filters['deadline__lte'] ?? ''}');
    if (dlLte != null) {
      tasks = tasks.where((task) {
        final dt = DateTime.tryParse(task.deadline ?? '');
        return dt != null && !dt.isAfter(dlLte);
      }).toList();
    }

    final searchQuery = search.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      tasks = tasks.where((task) {
        final name = (task.name ?? '').toLowerCase();
        final description = (task.description ?? '').toLowerCase();
        return name.contains(searchQuery) || description.contains(searchQuery);
      }).toList();
    }

    tasks.sort(_compareTasks);
    return tasks;
  }

  DateTime? getLastCheckSync(String key) {
    final raw = _syncMetaBox.get(key);
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  Future<void> setLastCheck(String key, DateTime value) async {
    await init();
    await _syncMetaBox.put(key, value.toIso8601String());
  }

  Future<void> enqueuePendingOp(TmsPendingOp op) async {
    await init();
    await _pendingOpsBox.put(op.opId, op.toJson());
  }

  Future<void> upsertPendingOp(TmsPendingOp op) async {
    await init();
    await _pendingOpsBox.put(op.opId, op.toJson());
  }

  TmsPendingOp? getPendingOpByIdSync(String opId) {
    final raw = _pendingOpsBox.get(opId);
    if (raw is! Map) return null;
    return TmsPendingOp.fromJson(Map<String, dynamic>.from(raw));
  }

  List<TmsPendingOp> getPendingOpsSync() {
    return _pendingOpsBox.values
        .whereType<Map>()
        .map((e) => TmsPendingOp.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> removePendingOp(String opId) async {
    await init();
    await _pendingOpsBox.delete(opId);
  }

  Future<void> removePendingOpsForEntity(int entityId) async {
    await init();
    final toDelete = <String>[];

    for (final entry in _pendingOpsBox.toMap().entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final op = TmsPendingOp.fromJson(Map<String, dynamic>.from(value));
      if (op.entityId == entityId) {
        toDelete.add(entry.key.toString());
      }
    }

    for (final key in toDelete) {
      await _pendingOpsBox.delete(key);
    }
  }

  Future<void> removePendingReorderOpsForProgress({
    required int projectId,
    required int progressId,
  }) async {
    await init();

    final toDelete = <String>[];

    for (final entry in _pendingOpsBox.toMap().entries) {
      final value = entry.value;
      if (value is! Map) continue;

      final op = TmsPendingOp.fromJson(Map<String, dynamic>.from(value));
      if (op.type != TmsPendingOpType.reorderTasks) continue;

      final opProjectId = int.tryParse('${op.payload['project_id']}');
      final opProgressId = int.tryParse('${op.payload['progress']}');

      if (opProjectId == projectId && opProgressId == progressId) {
        toDelete.add(entry.key.toString());
      }
    }

    for (final key in toDelete) {
      await _pendingOpsBox.delete(key);
    }
  }

  Future<void> replaceTaskId(int oldId, int newId) async {
    await init();

    int? affectedProjectId;

    final raw = _tasksBox.get('$oldId');
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);

      final projectIdRaw = map['projectId'] ??
          (map['project'] is Map ? (map['project'] as Map)['id'] : map['project']);

      affectedProjectId = projectIdRaw is int
          ? projectIdRaw
          : int.tryParse('$projectIdRaw');

      map['id'] = newId;
      await _tasksBox.put('$newId', map);
      await _tasksBox.delete('$oldId');
    }

    for (final key in _searchCacheBox.keys.map((e) => e.toString()).toList()) {
      final rawCache = _searchCacheBox.get(key);
      if (rawCache is! Map) continue;

      final cache = Map<String, dynamic>.from(rawCache);
      final ids = (cache['task_ids'] as List?)
              ?.map((e) => int.tryParse(e.toString()) ?? 0)
              .toList() ??
          <int>[];

      var changed = false;
      for (var i = 0; i < ids.length; i++) {
        if (ids[i] == oldId) {
          ids[i] = newId;
          changed = true;
        }
      }

      if (changed) {
        cache['task_ids'] = ids;
        await _searchCacheBox.put(key, cache);
      }
    }

    for (final key in _pendingOpsBox.keys.map((e) => e.toString()).toList()) {
      final rawOp = _pendingOpsBox.get(key);
      if (rawOp is! Map) continue;

      final op = TmsPendingOp.fromJson(Map<String, dynamic>.from(rawOp));
      var changed = false;
      final payload = Map<String, dynamic>.from(op.payload);

      int? nextEntityId = op.entityId;
      if (op.entityId == oldId) {
        nextEntityId = newId;
        changed = true;
      }

      for (final entry in payload.entries.toList()) {
        final value = entry.value;

        if (value == oldId) {
          payload[entry.key] = newId;
          changed = true;
        } else if (value is List) {
          final list = List<dynamic>.from(value);
          var listChanged = false;

          for (var i = 0; i < list.length; i++) {
            if (list[i] == oldId) {
              list[i] = newId;
              listChanged = true;
            }
          }

          if (listChanged) {
            payload[entry.key] = list;
            changed = true;
          }
        }
      }

      if (changed) {
        await _pendingOpsBox.put(
          key,
          op.copyWith(
            entityId: nextEntityId,
            payload: payload,
          ).toJson(),
        );
      }
    }

    if (affectedProjectId != null) {
      await rebuildBoardFromTaskBox(affectedProjectId);
    }
  }

  int? getProgressVersionSync({
    required int boardId,
    required int progressId,
  }) {
    final board = getBoardDetailsSync(boardId);
    if (board == null) return null;

    for (final progress in board.projectProgresses ?? const <ProjectProgresses>[]) {
      if (progress.id == progressId) {
        return progress.version;
      }
    }
    return null;
  }

  List<int> _parseIntList(dynamic raw) {
    if (raw == null) return const <int>[];

    if (raw is List) {
      return raw
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>()
          .toList();
    }

    return raw
        .toString()
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }

  bool? _parseBool(dynamic raw) {
    if (raw == null || '$raw'.trim().isEmpty) return null;

    final normalized = raw.toString().trim().toLowerCase();
    if (['1', 'true', 'yes', 'y', 'on'].contains(normalized)) return true;
    if (['0', 'false', 'no', 'n', 'off'].contains(normalized)) return false;

    return null;
  }

  int _compareTasks(Tasks a, Tasks b) {
    final ao = a.ordering ?? 0;
    final bo = b.ordering ?? 0;
    if (ao != bo) return ao.compareTo(bo);

    final at = DateTime.tryParse(a.timestamp ?? '');
    final bt = DateTime.tryParse(b.timestamp ?? '');
    if (at != null && bt != null) {
      final cmp = at.compareTo(bt);
      if (cmp != 0) return cmp;
    }

    return (a.id ?? 0).compareTo(b.id ?? 0);
  }
}