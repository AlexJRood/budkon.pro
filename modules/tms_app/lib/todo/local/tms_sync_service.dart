import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tms_app/todo/local/tms_local_store.dart';
import 'package:tms_app/todo/local/tms_pending_op.dart';
import 'package:tms_app/todo/local/tms_sync_status_provider.dart';
import 'package:tms_app/todo/models/board_details_model.dart';
import 'package:tms_app/todo/models/get_user_board_model.dart';
import 'package:tms_app/todo/models/tasks_model.dart';
import 'package:tms_app/todo/provider/urls_tms.dart';
import 'package:uuid/uuid.dart';

import 'package:core/platform/api_services.dart';

final tmsSyncServiceProvider = Provider<TmsSyncService>((ref) {
  final service = TmsSyncService(ref);
  ref.onDispose(service.dispose);
  return service;
});

enum _FlushSingleResultKind {
  success,
  retryLater,
  conflict,
}

class _FlushSingleResult {
  final _FlushSingleResultKind kind;
  final String? error;
  final Map<String, dynamic>? serverSnapshot;

  const _FlushSingleResult({
    required this.kind,
    this.error,
    this.serverSnapshot,
  });
}

class TmsSyncService {
  TmsSyncService(this.ref);

  final Ref ref;
  final Uuid _uuid = const Uuid();

  TmsLocalStore get _store => ref.read(tmsLocalStoreProvider);
  TmsSyncUiNotifier get _syncUi => ref.read(tmsSyncUiStateProvider.notifier);

  Completer<bool>? _flushCompleter;
  Timer? _periodicFlushTimer;
  bool _periodicFlushStarted = false;

  Future<void> init() async {
    await _store.init();
    _refreshSyncUiFromStore();
    _startPeriodicFlush();
  }

  void _startPeriodicFlush() {
    if (_periodicFlushStarted) return;
    _periodicFlushStarted = true;

    _periodicFlushTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) {
        unawaited(flushPendingOps());
      },
    );
  }

  void _refreshSyncUiFromStore() {
    final ops = _store.getPendingOpsSync();
    _syncUi.refreshFromOps(ops);
  }

  void dispose() {
    _periodicFlushTimer?.cancel();
    _periodicFlushTimer = null;
  }

  List<BoardResults> getLocalBoards() {
    return _store.getBoardsSync();
  }

  BoardDetailsModel? getLocalBoardDetails(int boardId) {
    return _store.getBoardDetailsSync(boardId);
  }

  List<Tasks> searchLocal({
    required int projectId,
    required Map<String, dynamic> filters,
    String search = '',
  }) {
    final key = _store.makeSearchKey(
      projectId: projectId,
      filters: filters,
      search: search,
    );

    final cached = _store.getSearchCacheSync(key);
    if (cached.isNotEmpty) return cached;

    return _store.searchLocalTasks(
      projectId: projectId,
      filters: filters,
      search: search,
    );
  }

  Future<List<BoardResults>> refreshBoards() async {
    await init();

    try {
      final response = await ApiServices.get(
        TmsURLs.apiTask,
        ref: ref,
        hasToken: true,
      );

      if (response == null || response.statusCode != 200) {
        return _store.getBoardsSync();
      }

      final decoded = _decodeMap(response.data);
      final model = BoardModel.fromJson(decoded);
      final boards = model.results ?? const <BoardResults>[];

      await _store.saveBoards(boards);
      return boards;
    } catch (e) {
      debugPrint('refreshBoards error: $e');
      return _store.getBoardsSync();
    }
  }

  Future<BoardDetailsModel?> syncBoard(
    int boardId, {
    bool force = false,
  }) async {
    await init();

    final queueClean = await flushPendingOps();
    final localBoard = _store.getBoardDetailsSync(boardId);

    if (!queueClean) {
      return localBoard;
    }

    final lastCheckKey = 'board:$boardId:last_check';
    final lastCheck = force ? null : _store.getLastCheckSync(lastCheckKey);
    final localCount = _store.getLocalCountForProject(boardId);
    final oldest = _store.getOldestTaskTimestampForProject(boardId);

    try {
      final checkResp = await ApiServices.post(
        TmsURLs.taskSyncCheck,
        hasToken: true,
        data: {
          'project_id': boardId,
          'last_check': lastCheck?.toIso8601String(),
          'local_count': localCount,
          'oldest_local_timestamp': oldest?.toIso8601String(),
        },
      );

      if (checkResp == null || checkResp.statusCode != 200) {
        return _store.getBoardDetailsSync(boardId);
      }

      final checkData = _decodeMap(checkResp.data);
      final needPull = checkData['need_pull'] == true;
      final structureChanged = checkData['structure_changed'] == true;
      final serverTime = DateTime.tryParse('${checkData['server_time']}');

      if (!needPull) {
        if (serverTime != null) {
          await _store.setLastCheck(lastCheckKey, serverTime);
        }
        return _store.getBoardDetailsSync(boardId);
      }

      if (localBoard == null || structureChanged) {
        final fullResp = await ApiServices.get(
          TmsURLs.projectDetails(boardId.toString()),
          ref: ref,
          hasToken: true,
        );

        if (fullResp != null && fullResp.statusCode == 200) {
          final fullMap = _decodeMap(fullResp.data);
          final board = BoardDetailsModel.fromJson(fullMap);
          await _store.saveBoardDetails(board);

          if (serverTime != null) {
            await _store.setLastCheck(lastCheckKey, serverTime);
          }

          return _store.getBoardDetailsSync(boardId);
        }
      }

      final pullResp = await ApiServices.post(
        TmsURLs.taskSyncPull,
        hasToken: true,
        data: {
          'project_id': boardId,
          'updated_since': lastCheck?.toIso8601String(),
          'limit': 3000,
        },
      );

      if (pullResp == null || pullResp.statusCode != 200) {
        return _store.getBoardDetailsSync(boardId);
      }

      final pullMap = _decodeMap(pullResp.data);

      final changedTasks = ((pullMap['results'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Tasks.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final deletedIds = ((pullMap['deleted_ids'] as List?) ?? const [])
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>()
          .toList();

      await _store.upsertTasks(changedTasks);
      await _store.deleteTasks(deletedIds);
      await _store.rebuildBoardFromTaskBox(boardId);
      await _store.clearSearchCacheForProject(boardId);

      final pullServerTime = DateTime.tryParse('${pullMap['server_time']}');
      if (pullServerTime != null) {
        await _store.setLastCheck(lastCheckKey, pullServerTime);
      } else if (serverTime != null) {
        await _store.setLastCheck(lastCheckKey, serverTime);
      }

      return _store.getBoardDetailsSync(boardId);
    } catch (e) {
      debugPrint('syncBoard error: $e');
      return _store.getBoardDetailsSync(boardId);
    }
  }

  Future<List<Tasks>> refreshSearch({
    required int projectId,
    required Map<String, dynamic> filters,
    String search = '',
  }) async {
    await init();

    final queueClean = await flushPendingOps();

    final key = _store.makeSearchKey(
      projectId: projectId,
      filters: filters,
      search: search,
    );

    final localTasks = _store.getSearchCacheSync(key);

    if (!queueClean) {
      return localTasks.isNotEmpty
          ? localTasks
          : _store.searchLocalTasks(
              projectId: projectId,
              filters: filters,
              search: search,
            );
    }

    final lastCheck = _store.getLastCheckSync('search:$key');

    try {
      final checkResp = await ApiServices.post(
        TmsURLs.taskSyncCheck,
        hasToken: true,
        data: {
          'project_id': projectId,
          'last_check': lastCheck?.toIso8601String(),
          'local_count': localTasks.length,
          'filters': filters,
          'search': search,
        },
      );

      if (checkResp == null || checkResp.statusCode != 200) {
        return localTasks.isNotEmpty
            ? localTasks
            : _store.searchLocalTasks(
                projectId: projectId,
                filters: filters,
                search: search,
              );
      }

      final checkMap = _decodeMap(checkResp.data);
      final needPull = checkMap['need_pull'] == true;
      final serverTime = DateTime.tryParse('${checkMap['server_time']}');

      if (!needPull) {
        if (serverTime != null) {
          await _store.setLastCheck('search:$key', serverTime);
        }
        return localTasks.isNotEmpty
            ? localTasks
            : _store.searchLocalTasks(
                projectId: projectId,
                filters: filters,
                search: search,
              );
      }

      final pullResp = await ApiServices.post(
        TmsURLs.taskSyncPull,
        hasToken: true,
        data: {
          'project_id': projectId,
          'updated_since': null,
          'filters': filters,
          'search': search,
          'limit': 3000,
        },
      );

      if (pullResp == null || pullResp.statusCode != 200) {
        return localTasks.isNotEmpty
            ? localTasks
            : _store.searchLocalTasks(
                projectId: projectId,
                filters: filters,
                search: search,
              );
      }

      final pullMap = _decodeMap(pullResp.data);

      final tasks = ((pullMap['results'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Tasks.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final deletedIds = ((pullMap['deleted_ids'] as List?) ?? const [])
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>()
          .toList();

      await _store.upsertTasks(tasks);
      if (deletedIds.isNotEmpty) {
        await _store.deleteTasks(deletedIds);
      }

      final checkedAt =
          DateTime.tryParse('${pullMap['server_time']}') ??
              serverTime ??
              DateTime.now();

      await _store.saveSearchCache(
        key: key,
        projectId: projectId,
        filters: filters,
        search: search,
        tasks: tasks,
        checkedAt: checkedAt,
      );
      await _store.setLastCheck('search:$key', checkedAt);

      return _store.getSearchCacheSync(key);
    } catch (e) {
      debugPrint('refreshSearch error: $e');
      return localTasks.isNotEmpty
          ? localTasks
          : _store.searchLocalTasks(
              projectId: projectId,
              filters: filters,
              search: search,
            );
    }
  }

  List<int> _sanitizeOrderedTaskIdsForProgress({
    required int progressId,
    required List<int> orderedTaskIds,
  }) {
    final currentTasks = _store.getTasksForProgressSync(progressId);
    final currentIds = currentTasks.map((e) => e.id).whereType<int>().toSet();

    final seen = <int>{};
    final sanitized = <int>[];

    for (final id in orderedTaskIds) {
      if (currentIds.contains(id) && seen.add(id)) {
        sanitized.add(id);
      }
    }

    for (final task in currentTasks) {
      final id = task.id;
      if (id != null && seen.add(id)) {
        sanitized.add(id);
      }
    }

    return sanitized;
  }

  Future<void> createTaskOptimistic({
    required int projectId,
    required int progressId,
    required int userId,
    required String taskName,
  }) async {
    await init();

    final tempId = -DateTime.now().microsecondsSinceEpoch;
    final nowIso = DateTime.now().toIso8601String();
    final ordering = _store.getTasksForProgressSync(progressId).length + 1;

    final task = Tasks(
      id: tempId,
      progressId: progressId,
      progress: Progress(
        id: progressId,
        projectId: projectId,
        name: null,
        timestamp: null,
        updatedAt: nowIso,
        version: null,
      ),
      name: taskName,
      description: 'Description for Tasks',
      isCompleted: false,
      priority: 'H',
      ordering: ordering,
      metaFields: const MetaFields(someField: 'attribute'),
      timestamp: nowIso,
      updatedAt: nowIso,
      deadline: null,
      commentsCount: 0,
      members: const [],
      labels: const [],
      tmsTaskChecklist: const [],
      projectId: projectId,
      project: null,
      assignedToUser: userId,
      files: const [],
      tags: const [],
      assignedTo: null,
      clientId: null,
      transactionObjectId: null,
      transactionContentType: null,
      dateStart: null,
      dateEnd: null,
      version: null,
    );

    await _store.upsertTasks([task]);
    await _store.rebuildBoardFromTaskBox(projectId);
    await _store.clearSearchCacheForProject(projectId);

    // Usuwamy stare reorder ops dla tej kolumny,
    // bo po create serwer i tak ustawi ordering końcowy.
    await _store.removePendingReorderOpsForProgress(
      projectId: projectId,
      progressId: progressId,
    );

    await _store.enqueuePendingOp(
      TmsPendingOp(
        opId: _uuid.v4(),
        type: TmsPendingOpType.createTask,
        entityId: tempId,
        createdAt: DateTime.now(),
        payload: {
          'project': projectId.toString(),
          'name': taskName,
          'description': 'Description for Tasks',
          'priority': 'H',
          'meta_fields': {'some-field': 'attribute'},
          'progress': progressId,
          'user': userId,
        },
        baseVersion: null,
      ),
    );

    _refreshSyncUiFromStore();
    unawaited(flushPendingOps());
  }

  Future<void> patchTaskOptimistic({
    required int projectId,
    required int taskId,
    required Map<String, dynamic> patch,
  }) async {
    await init();

    final current = _store.getTaskByIdSync(taskId);
    if (current == null) return;

    final updated = current.copyWith(
      name: patch.containsKey('name') ? patch['name']?.toString() : current.name,
      description: patch.containsKey('description')
          ? patch['description']?.toString()
          : current.description,
      priority: patch.containsKey('priority')
          ? patch['priority']?.toString()
          : current.priority,
      deadline: patch.containsKey('deadline')
          ? patch['deadline']?.toString()
          : current.deadline,
      isCompleted: patch.containsKey('is_completed')
          ? patch['is_completed'] as bool
          : current.isCompleted,
      labels: patch.containsKey('label')
          ? (patch['label'] as List)
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e != 0)
              .toList()
          : current.labels,
      members: patch.containsKey('members')
          ? (patch['members'] as List)
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e != 0)
              .toList()
          : current.members,
      assignedTo: patch.containsKey('assigned_to')
          ? int.tryParse('${patch['assigned_to']}')
          : current.assignedTo,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await _store.upsertTasks([updated]);
    await _store.rebuildBoardFromTaskBox(projectId);
    await _store.clearSearchCacheForProject(projectId);

    await _store.enqueuePendingOp(
      TmsPendingOp(
        opId: _uuid.v4(),
        type: TmsPendingOpType.patchTask,
        entityId: taskId,
        createdAt: DateTime.now(),
        payload: {
          ...patch,
          'base_version': current.version,
        },
        baseVersion: current.version,
      ),
    );

    _refreshSyncUiFromStore();
    unawaited(flushPendingOps());
  }

  Future<void> moveTaskOptimistic({
    required int projectId,
    required int taskId,
    required int newProgressId,
  }) async {
    await init();

    final current = _store.getTaskByIdSync(taskId);
    if (current == null) return;

    final oldProgressId = current.progressId;
    final nowIso = DateTime.now().toIso8601String();
    final updatedTasks = <Tasks>[];

    if (oldProgressId != null) {
      final oldTasks = _store
          .getTasksForProgressSync(oldProgressId)
          .where((task) => task.id != taskId)
          .toList();

      for (var i = 0; i < oldTasks.length; i++) {
        updatedTasks.add(
          oldTasks[i].copyWith(
            ordering: i + 1,
            updatedAt: nowIso,
          ),
        );
      }
    }

    final newTasks = _store
        .getTasksForProgressSync(newProgressId)
        .where((task) => task.id != taskId)
        .toList();

    final movedTask = current.copyWith(
      progressId: newProgressId,
      progress: current.progress?.copyWith(
        id: newProgressId,
        updatedAt: nowIso,
      ),
      ordering: newTasks.length + 1,
      updatedAt: nowIso,
    );

    updatedTasks.add(movedTask);

    await _store.upsertTasks(updatedTasks);
    await _store.rebuildBoardFromTaskBox(projectId);
    await _store.clearSearchCacheForProject(projectId);

    // Usuwamy stare reorder ops dla starej i nowej kolumny,
    // bo po move payload reorder może zawierać taski, które już zmieniły kolumnę.
    if (oldProgressId != null) {
      await _store.removePendingReorderOpsForProgress(
        projectId: projectId,
        progressId: oldProgressId,
      );
    }
    await _store.removePendingReorderOpsForProgress(
      projectId: projectId,
      progressId: newProgressId,
    );

    await _store.enqueuePendingOp(
      TmsPendingOp(
        opId: _uuid.v4(),
        type: TmsPendingOpType.moveTask,
        entityId: taskId,
        createdAt: DateTime.now(),
        payload: {
          'task_id': taskId,
          'progress': newProgressId,
          'base_version': current.version,
        },
        baseVersion: current.version,
      ),
    );

    _refreshSyncUiFromStore();
    unawaited(flushPendingOps());
  }

  Future<void> reorderTasksOptimistic({
    required int projectId,
    required int progressId,
    required List<int> orderedTaskIds,
  }) async {
    await init();

    final progressVersion = _store.getProgressVersionSync(
      boardId: projectId,
      progressId: progressId,
    );

    final currentTasks = _store.getTasksForProgressSync(progressId);
    if (currentTasks.isEmpty) return;

    final sanitizedOrderedIds = _sanitizeOrderedTaskIdsForProgress(
      progressId: progressId,
      orderedTaskIds: orderedTaskIds,
    );

    final byId = <int, Tasks>{};
    for (final task in currentTasks) {
      final id = task.id;
      if (id == null) continue;
      byId[id] = task;
    }

    final normalized = <Tasks>[];
    final nowIso = DateTime.now().toIso8601String();

    for (var i = 0; i < sanitizedOrderedIds.length; i++) {
      final task = byId[sanitizedOrderedIds[i]];
      if (task == null) continue;

      normalized.add(
        task.copyWith(
          ordering: i + 1,
          updatedAt: nowIso,
        ),
      );
    }

    await _store.upsertTasks(normalized);
    await _store.rebuildBoardFromTaskBox(projectId);
    await _store.clearSearchCacheForProject(projectId);

    await _store.removePendingReorderOpsForProgress(
      projectId: projectId,
      progressId: progressId,
    );

    await _store.enqueuePendingOp(
      TmsPendingOp(
        opId: _uuid.v4(),
        type: TmsPendingOpType.reorderTasks,
        entityId: progressId,
        createdAt: DateTime.now(),
        payload: {
          'project_id': projectId,
          'progress': progressId,
          'tasks': sanitizedOrderedIds,
          'base_version': progressVersion,
        },
        baseVersion: progressVersion,
      ),
    );

    _refreshSyncUiFromStore();
    unawaited(flushPendingOps());
  }

  Future<void> deleteTaskOptimistic({
    required int projectId,
    required int taskId,
  }) async {
    await init();

    final current = _store.getTaskByIdSync(taskId);
    final oldProgressId = current?.progressId;
    final nowIso = DateTime.now().toIso8601String();

    await _store.deleteTasks([taskId]);

    if (oldProgressId != null) {
      final remaining = _store.getTasksForProgressSync(oldProgressId);
      final normalized = <Tasks>[];
      for (var i = 0; i < remaining.length; i++) {
        normalized.add(
          remaining[i].copyWith(
            ordering: i + 1,
            updatedAt: nowIso,
          ),
        );
      }
      await _store.upsertTasks(normalized);
    }

    await _store.rebuildBoardFromTaskBox(projectId);
    await _store.clearSearchCacheForProject(projectId);

    if (oldProgressId != null) {
      await _store.removePendingReorderOpsForProgress(
        projectId: projectId,
        progressId: oldProgressId,
      );
    }

    if (taskId < 0) {
      await _store.removePendingOpsForEntity(taskId);
      _refreshSyncUiFromStore();
      return;
    }

    await _store.enqueuePendingOp(
      TmsPendingOp(
        opId: _uuid.v4(),
        type: TmsPendingOpType.deleteTask,
        entityId: taskId,
        createdAt: DateTime.now(),
        payload: {
          'task_id': taskId,
          'base_version': current?.version,
        },
        baseVersion: current?.version,
      ),
    );

    _refreshSyncUiFromStore();
    unawaited(flushPendingOps());
  }

  Future<bool> flushPendingOps() async {
    await init();

    if (_flushCompleter != null) {
      return _flushCompleter!.future;
    }

    _flushCompleter = Completer<bool>();
    _refreshSyncUiFromStore();

    try {
      var safety = 0;

      while (safety < 1000) {
        safety++;

        final ops = _store.getPendingOpsSync();
        if (ops.isEmpty) {
          _syncUi.markSyncedNow();
          _flushCompleter!.complete(true);
          return true;
        }

        final now = DateTime.now();

        final TmsPendingOp? nextOp = ops.cast<TmsPendingOp?>().firstWhere(
              (op) =>
                  op != null &&
                  op.status != TmsPendingOpStatus.conflict &&
                  (op.nextRetryAt == null || !op.nextRetryAt!.isAfter(now)),
              orElse: () => null,
            );

        if (nextOp == null) {
          _refreshSyncUiFromStore();
          _flushCompleter!.complete(false);
          return false;
        }

        await _store.upsertPendingOp(
          nextOp.copyWith(
            status: TmsPendingOpStatus.syncing,
            retryCount: nextOp.retryCount + 1,
            lastAttemptAt: now,
            clearLastError: true,
            clearNextRetryAt: true,
          ),
        );
        _refreshSyncUiFromStore();

        final result = await _flushSingleOp(nextOp);

        if (result.kind == _FlushSingleResultKind.success) {
          _refreshSyncUiFromStore();
          continue;
        }

        if (result.kind == _FlushSingleResultKind.conflict) {
          await _store.upsertPendingOp(
            nextOp.copyWith(
              status: TmsPendingOpStatus.conflict,
              lastError: result.error ?? 'Conflict detected',
              serverSnapshot: result.serverSnapshot,
              clearNextRetryAt: true,
            ),
          );
          _refreshSyncUiFromStore();
          _flushCompleter!.complete(false);
          return false;
        }

        final backoffSeconds = _retryBackoffSeconds(nextOp.retryCount);
        await _store.upsertPendingOp(
          nextOp.copyWith(
            status: TmsPendingOpStatus.failed,
            lastError: result.error ?? 'Sync failed',
            nextRetryAt: now.add(Duration(seconds: backoffSeconds)),
          ),
        );
        _refreshSyncUiFromStore();
        _flushCompleter!.complete(false);
        return false;
      }

      final clean = _store.getPendingOpsSync().isEmpty;
      if (clean) {
        _syncUi.markSyncedNow();
      } else {
        _refreshSyncUiFromStore();
      }
      _flushCompleter!.complete(clean);
      return clean;
    } catch (e) {
      debugPrint('flushPendingOps fatal error: $e');
      _refreshSyncUiFromStore();
      final clean = _store.getPendingOpsSync().isEmpty;
      _flushCompleter!.complete(clean);
      return clean;
    } finally {
      _flushCompleter = null;
    }
  }

  int _retryBackoffSeconds(int retryCount) {
    if (retryCount <= 1) return 10;
    if (retryCount == 2) return 30;
    if (retryCount == 3) return 60;
    if (retryCount == 4) return 180;
    return 300;
  }

  Future<_FlushSingleResult> _flushSingleOp(TmsPendingOp op) async {
    try {
      switch (op.type) {
        case TmsPendingOpType.createTask:
          final response = await ApiServices.post(
            TmsURLs.addTask,
            hasToken: true,
            data: op.payload,
          );

          if (response == null) {
            return const _FlushSingleResult(
              kind: _FlushSingleResultKind.retryLater,
              error: 'No response from server',
            );
          }

          if (response.statusCode == 409) {
            return _FlushSingleResult(
              kind: _FlushSingleResultKind.conflict,
              error: 'Create task conflict',
              serverSnapshot: _tryDecodeConflict(response.data),
            );
          }

          if (response.statusCode != 200 && response.statusCode != 201) {
            return _FlushSingleResult(
              kind: _FlushSingleResultKind.retryLater,
              error: 'Create task failed (${response.statusCode})',
            );
          }

          final body = _decodeMap(response.data);
          final created = Tasks.fromJson(body);

          if (op.entityId != null && created.id != null) {
            await _store.replaceTaskId(op.entityId!, created.id!);
          }

          await _store.upsertTasks([created]);

          final projectId =
              created.projectId ?? int.tryParse('${op.payload['project']}');
          if (projectId != null) {
            await _store.rebuildBoardFromTaskBox(projectId);
            await _store.clearSearchCacheForProject(projectId);
          }

          await _store.removePendingOp(op.opId);
          return const _FlushSingleResult(kind: _FlushSingleResultKind.success);

        case TmsPendingOpType.patchTask:
          if (op.entityId == null) {
            return const _FlushSingleResult(
              kind: _FlushSingleResultKind.retryLater,
              error: 'Missing task id',
            );
          }

          final patchResp = await ApiServices.patch(
            TmsURLs.editTask(op.entityId.toString()),
            hasToken: true,
            data: op.payload,
          );

          if (patchResp == null) {
            return const _FlushSingleResult(
              kind: _FlushSingleResultKind.retryLater,
              error: 'No response from server',
            );
          }

          if (patchResp.statusCode == 409) {
            return _FlushSingleResult(
              kind: _FlushSingleResultKind.conflict,
              error: 'Task changed on another device',
              serverSnapshot: _tryDecodeConflict(patchResp.data),
            );
          }

          if (patchResp.statusCode != 200) {
            return _FlushSingleResult(
              kind: _FlushSingleResultKind.retryLater,
              error: 'Patch failed (${patchResp.statusCode})',
            );
          }

          final rawTask = _store.getTaskByIdSync(op.entityId!);
          final projectId = rawTask?.projectId;

          try {
            final body = _decodeMap(patchResp.data);
            final updated = Tasks.fromJson(body);
            await _store.upsertTasks([updated]);
          } catch (_) {}

          if (projectId != null) {
            await _store.rebuildBoardFromTaskBox(projectId);
            await _store.clearSearchCacheForProject(projectId);
          }

          await _store.removePendingOp(op.opId);
          return const _FlushSingleResult(kind: _FlushSingleResultKind.success);

        case TmsPendingOpType.moveTask:
          final taskId = op.payload['task_id'];
          final progress = op.payload['progress'];

          final moveResp = await ApiServices.post(
            TmsURLs.reProgressTask(taskId.toString()),
            hasToken: true,
            data: {
              'progress': progress,
              'base_version': op.payload['base_version'],
            },
          );

          if (moveResp == null) {
            return const _FlushSingleResult(
              kind: _FlushSingleResultKind.retryLater,
              error: 'No response from server',
            );
          }

          if (moveResp.statusCode == 409) {
            return _FlushSingleResult(
              kind: _FlushSingleResultKind.conflict,
              error: 'Task move conflict',
              serverSnapshot: _tryDecodeConflict(moveResp.data),
            );
          }

          if (moveResp.statusCode != 200) {
            return _FlushSingleResult(
              kind: _FlushSingleResultKind.retryLater,
              error: 'Move failed (${moveResp.statusCode})',
            );
          }

          await _store.removePendingOp(op.opId);
          return const _FlushSingleResult(kind: _FlushSingleResultKind.success);

        case TmsPendingOpType.reorderTasks:
          final reorderResp = await ApiServices.post(
            TmsURLs.reOrderTask('${op.payload['project_id']}'),
            hasToken: true,
            data: {
              'progress': op.payload['progress'],
              'tasks': op.payload['tasks'],
              'base_version': op.payload['base_version'],
            },
          );

          if (reorderResp == null) {
            return const _FlushSingleResult(
              kind: _FlushSingleResultKind.retryLater,
              error: 'No response from server',
            );
          }

          if (reorderResp.statusCode == 409) {
            return _FlushSingleResult(
              kind: _FlushSingleResultKind.conflict,
              error: 'Column order conflict',
              serverSnapshot: _tryDecodeConflict(reorderResp.data),
            );
          }

          if (reorderResp.statusCode != 200) {
            return _FlushSingleResult(
              kind: _FlushSingleResultKind.retryLater,
              error: 'Reorder failed (${reorderResp.statusCode})',
            );
          }

          try {
            final body = _decodeMap(reorderResp.data);

            final returnedTasks = ((body['tasks'] as List?) ?? const [])
                .whereType<Map>()
                .map((e) => Tasks.fromJson(Map<String, dynamic>.from(e)))
                .toList();

            if (returnedTasks.isNotEmpty) {
              await _store.upsertTasks(returnedTasks);
            }

            final projectId = int.tryParse('${op.payload['project_id']}');
            if (projectId != null) {
              await _store.rebuildBoardFromTaskBox(projectId);
              await _store.clearSearchCacheForProject(projectId);
            }
          } catch (e) {
            debugPrint('reorder success reconcile warning: $e');
          }

          await _store.removePendingOp(op.opId);
          return const _FlushSingleResult(kind: _FlushSingleResultKind.success);

        case TmsPendingOpType.deleteTask:
          final taskId = op.payload['task_id'];
          final deleteUrl = op.payload['base_version'] == null
              ? TmsURLs.deleteTask(taskId.toString())
              : '${TmsURLs.deleteTask(taskId.toString())}?base_version=${Uri.encodeQueryComponent('${op.payload['base_version']}')}';

          final deleteResp = await ApiServices.delete(
            deleteUrl,
            hasToken: true,
          );

          if (deleteResp == null) {
            return const _FlushSingleResult(
              kind: _FlushSingleResultKind.retryLater,
              error: 'No response from server',
            );
          }

          if (deleteResp.statusCode == 409) {
            return _FlushSingleResult(
              kind: _FlushSingleResultKind.conflict,
              error: 'Delete conflict',
              serverSnapshot: _tryDecodeConflict(deleteResp.data),
            );
          }

          if (deleteResp.statusCode == 200 ||
              deleteResp.statusCode == 204 ||
              deleteResp.statusCode == 404) {
            await _store.removePendingOp(op.opId);
            return const _FlushSingleResult(kind: _FlushSingleResultKind.success);
          }

          return _FlushSingleResult(
            kind: _FlushSingleResultKind.retryLater,
            error: 'Delete failed (${deleteResp.statusCode})',
          );
      }
    } catch (e) {
      debugPrint('flushPendingOps error (${op.type.name}): $e');
      return _FlushSingleResult(
        kind: _FlushSingleResultKind.retryLater,
        error: e.toString(),
      );
    }
  }

  Future<void> discardConflict(String opId) async {
    await init();
    await _store.removePendingOp(opId);
    _refreshSyncUiFromStore();
  }

  Future<void> retryConflictKeepingLocal(String opId) async {
    await init();

    final op = _store.getPendingOpByIdSync(opId);
    if (op == null) return;

    final snapshot = op.serverSnapshot ?? const <String, dynamic>{};
    final serverVersionRaw =
        snapshot['server_version'] ??
        (snapshot['server_object'] is Map
            ? (snapshot['server_object'] as Map)['version']
            : null);

    final serverVersion = serverVersionRaw is int
        ? serverVersionRaw
        : int.tryParse('$serverVersionRaw');

    final nextPayload = Map<String, dynamic>.from(op.payload);
    if (serverVersion != null) {
      nextPayload['base_version'] = serverVersion;
    }

    await _store.upsertPendingOp(
      op.copyWith(
        payload: nextPayload,
        status: TmsPendingOpStatus.pending,
        clearLastError: true,
        clearNextRetryAt: true,
        clearServerSnapshot: true,
        baseVersion: serverVersion ?? op.baseVersion,
      ),
    );

    _refreshSyncUiFromStore();
    unawaited(flushPendingOps());
  }

  Map<String, dynamic>? _tryDecodeConflict(dynamic data) {
    try {
      return _decodeMap(data);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decodeMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    if (data is Uint8List) {
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(data)));
    }

    if (data is List<int>) {
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(data)));
    }

    if (data is String) {
      return Map<String, dynamic>.from(jsonDecode(data));
    }

    throw StateError('Unsupported response type: ${data.runtimeType}');
  }
}