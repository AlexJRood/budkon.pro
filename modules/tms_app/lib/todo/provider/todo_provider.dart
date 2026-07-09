import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:core/platform/navigation_service.dart';

import 'package:core/platform/api_services.dart';
import 'package:tms_app/todo/board/provider/board_details_provider.dart';
import 'package:tms_app/todo/board/provider/board_provider.dart';
import 'package:tms_app/todo/local/tms_sync_service.dart';
import 'package:tms_app/todo/local/tms_sync_status_provider.dart';
import 'package:tms_app/todo/models/board_progress_model.dart';
import 'package:tms_app/todo/models/tasks_model.dart';
import 'package:tms_app/todo/provider/urls_tms.dart';
import 'package:core/user/user/user_provider.dart';

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

  throw StateError('Unsupported map response type: ${data.runtimeType}');
}

List<dynamic> _decodeList(dynamic data) {
  if (data is List<dynamic>) return data;
  if (data is Uint8List) return List<dynamic>.from(jsonDecode(utf8.decode(data)));
  if (data is List<int>) return List<dynamic>.from(jsonDecode(utf8.decode(data)));
  if (data is String) return List<dynamic>.from(jsonDecode(data));

  throw StateError('Unsupported list response type: ${data.runtimeType}');
}

void _setSyncMessage(Ref ref, String message) {
  try {
    ref.read(tmsSyncUiStateProvider.notifier).setMessage(message);
  } catch (_) {}
}

class CommentModel {
  final int id;
  final CommentUserModel user;
  final String title;
  final String comment;
  final String timestamp;
  final int task;

  CommentModel({
    required this.id,
    required this.user,
    required this.title,
    required this.comment,
    required this.timestamp,
    required this.task,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as int,
      user: CommentUserModel.fromJson(
        Map<String, dynamic>.from(json['user'] as Map),
      ),
      title: json['title'] as String,
      comment: json['comment'] as String,
      timestamp: json['timestamp'] as String,
      task: json['task'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'title': title,
      'comment': comment,
      'timestamp': timestamp,
      'task': task,
    };
  }

  CommentModel copyWith({
    int? id,
    CommentUserModel? user,
    String? title,
    String? comment,
    String? timestamp,
    int? task,
  }) {
    return CommentModel(
      id: id ?? this.id,
      user: user ?? this.user,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
      task: task ?? this.task,
    );
  }
}

class CommentUserModel {
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatar;

  CommentUserModel({
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatar,
  });

  factory CommentUserModel.fromJson(Map<String, dynamic> json) {
    return CommentUserModel(
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'avatar': avatar,
    };
  }

  CommentUserModel copyWith({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? avatar,
  }) {
    return CommentUserModel(
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
    );
  }
}

class CommentsNotifier extends StateNotifier<List<CommentModel>> {
  CommentsNotifier() : super([]);

  Future<void> fetchComments(String taskId, dynamic ref) async {
    try {
      state = [];

      final response = await ApiServices.get(
        TmsURLs.getComments(taskId),
        ref: ref,
        hasToken: true,
      );

      if (response == null || response.statusCode != 200) {
        debugPrint('❌ Fetch comments failed: ${response?.statusCode}');
        return;
      }

      final decodedData = _decodeList(response.data);
      state = decodedData
          .whereType<Map>()
          .map((comment) => CommentModel.fromJson(Map<String, dynamic>.from(comment)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching comments: $e');
    }
  }

  Future<void> addComment(
    String taskId,
    String content,
    String author,
    dynamic ref,
  ) async {
    try {
      final response = await ApiServices.post(
        TmsURLs.addComment(taskId),
        hasToken: true,
        data: {
          'task': int.tryParse(taskId),
          'title': author,
          'comment': content,
        },
      );

      if (response == null || response.statusCode != 201) {
        debugPrint('❌ Error adding comment: ${response?.statusCode}');
        debugPrint('❌ Validation errors: ${response?.data}');
        throw Exception('Failed to add comment - Status: ${response?.statusCode}');
      }

      final comment = CommentModel.fromJson(_decodeMap(response.data));
      state = [...state, comment];
    } catch (e) {
      debugPrint('❌ Error adding comment: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(int taskId, int commentId) async {
    try {
      final response = await ApiServices.post(
        TmsURLs.deleteComments(taskId.toString(), commentId.toString()),
        hasToken: true,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 204)) {
        state = state.where((comment) => comment.id != commentId).toList();
      } else {
        debugPrint('❌ Comment delete failed: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting comment: $e');
    }
  }
}

final commentsProvider =
    StateNotifierProvider<CommentsNotifier, List<CommentModel>>(
  (ref) => CommentsNotifier(),
);

enum TaskState { initial, loading, success, error }

class TaskDataState {
  final TaskState status;
  final List<Tasks> tasks;

  const TaskDataState({
    this.status = TaskState.initial,
    this.tasks = const [],
  });

  TaskDataState copyWith({
    TaskState? status,
    List<Tasks>? tasks,
  }) {
    return TaskDataState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
    );
  }
}

class TaskNotifier extends StateNotifier<TaskDataState> {
  TaskNotifier(this.ref) : super(const TaskDataState());

  final Ref ref;

  Future<dynamic> addTask(
    String taskName,
    int columnNumber,
    String projectId, {
    bool needMatchingItem = true,
  }) async {
    try {
      state = state.copyWith(status: TaskState.loading);

      final boardDetails = ref.read(boardDetailsStateProvider);
      final userAsyncValue = ref.read(userProvider);

      final progresses = boardDetails.projectProgresses ?? const [];
      int? progressId;

      if (needMatchingItem) {
        if (columnNumber >= 0 && columnNumber < progresses.length) {
          progressId = progresses[columnNumber].id;
        }
      } else {
        progressId = columnNumber;
      }

      if (progressId == null) {
        state = state.copyWith(status: TaskState.error);
        throw StateError(
          'Could not resolve progressId for column $columnNumber',
        );
      }

      final sync = ref.read(tmsSyncServiceProvider);

      await sync.createTaskOptimistic(
        projectId: int.parse(projectId),
        progressId: progressId,
        userId: userAsyncValue.value?.idInt ?? 0,
        taskName: taskName,
      );

      _setSyncMessage(ref, 'Task saved locally and queued for sync.');

      await ref
          .read(boardDetailsManagementProvider.notifier)
          .fetchBoardDetails(projectId);

      state = state.copyWith(status: TaskState.success);

      return {
        'queued_local': true,
        'project_id': int.tryParse(projectId),
        'progress_id': progressId,
        'task_name': taskName,
      };
    } catch (e) {
      debugPrint('Error adding task: $e');
      state = state.copyWith(status: TaskState.error);
      rethrow;
    }
  }

  Future<void> moveTaskToAnotherBoard({
    required int taskId,
    required int targetProjectId,
    required int targetProgressId,
  }) async {
    state = state.copyWith(status: TaskState.loading);

    try {
      final resp = await ApiServices.patch(
        TmsURLs.editTask(taskId.toString()),
        hasToken: true,
        data: {
          'project': targetProjectId,
          'progress': targetProgressId,
        },
      );

      if (resp == null || (resp.statusCode != 200 && resp.statusCode != 204)) {
        throw Exception('Failed to move task (status: ${resp?.statusCode})');
      }

      _setSyncMessage(ref, 'Task moved successfully.');
      state = state.copyWith(status: TaskState.success);
    } catch (e) {
      debugPrint('moveTaskToAnotherBoard error: $e');
      state = state.copyWith(status: TaskState.error);
      rethrow;
    }
  }

  Future<dynamic> addTaskFull(Map<String, dynamic> data) async {
    try {
      final response = await ApiServices.post(
        TmsURLs.addTask,
        hasToken: true,
        data: data,
      );

      if (response != null &&
          (response.statusCode == 201 || response.statusCode == 200)) {
        await ref.read(tmsSyncServiceProvider).flushPendingOps();
        return response.data;
      } else {
        debugPrint('❌ Error creating task: ${response?.statusCode}');
        debugPrint('❌ API validation error: ${response?.data}');
        throw Exception('Failed to create task');
      }
    } catch (e) {
      debugPrint('❌ Exception while creating task: $e');
      if (e is DioException && e.response != null) {
        debugPrint('❌ API Error Body: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<int> addProgressBar(String projectId, String name) async {
    try {
      state = state.copyWith(status: TaskState.loading);

      final response = await ApiServices.post(
        TmsURLs.addProgressBar(projectId),
        hasToken: true,
        data: {'project': projectId, 'name': name},
      );

      if (response == null || response.statusCode != 201) {
        state = state.copyWith(status: TaskState.error);
        throw Exception(
          'Failed to add progressBar (status: ${response?.statusCode})',
        );
      }

      final dynamic body = response.data;
      int? createdId;

      if (body is Map) {
        createdId = _extractIdFromMap(body);
      } else if (body is String) {
        final parsed = json.decode(body);
        if (parsed is Map) createdId = _extractIdFromMap(parsed);
      } else if (body is List<int>) {
        final parsed = json.decode(utf8.decode(body));
        if (parsed is Map) createdId = _extractIdFromMap(parsed);
      } else if (body is Uint8List) {
        final parsed = json.decode(utf8.decode(body));
        if (parsed is Map) createdId = _extractIdFromMap(parsed);
      }

      if (createdId == null) {
        state = state.copyWith(status: TaskState.error);
        throw StateError('Server did not return a new progress id');
      }

      _setSyncMessage(ref, 'Column created successfully.');
      state = state.copyWith(status: TaskState.success);
      return createdId;
    } catch (e) {
      debugPrint('Error adding progressBar: $e');
      state = state.copyWith(status: TaskState.error);
      rethrow;
    }
  }

  int? _extractIdFromMap(Map data) {
    final dynamic id =
        data['id'] ??
        (data['data'] is Map ? data['data']['id'] : null) ??
        (data['progress'] is Map ? data['progress']['id'] : null);

    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  Future<void> deleteProgressBar(String projectId, String progressId) async {
    try {
      final response = await ApiServices.delete(
        TmsURLs.deleteProgressBar(projectId, progressId),
        hasToken: true,
      );

      if (response == null || response.statusCode != 204) {
        throw Exception('Progress delete failed');
      }

      _setSyncMessage(ref, 'Column deleted successfully.');
    } catch (e) {
      if (kDebugMode) debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> updateProgressBar({
    required String projectId,
    required String progressId,
    required String name,
  }) async {
    try {
      final response = await ApiServices.put(
        TmsURLs.updateProgressBar(projectId, progressId),
        hasToken: true,
        data: {'name': name},
      );

      if (response == null || response.statusCode != 200) {
        throw Exception('Progress update failed');
      }

      _setSyncMessage(ref, 'Column updated successfully.');
    } catch (e) {
      if (kDebugMode) debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> reOrderTask({
    required int projectId,
    required int progressId,
    required List<int> orderedTaskIds,
  }) async {
    try {
      await ref.read(tmsSyncServiceProvider).reorderTasksOptimistic(
            projectId: projectId,
            progressId: progressId,
            orderedTaskIds: orderedTaskIds,
          );

      _setSyncMessage(ref, 'Order changed locally. Sync in progress.');
    } catch (e) {
      debugPrint('Error in reOrderTask: $e');
    }
  }

  Future<void> reProgressTask(int taskId, int newProgressId) async {
    state = state.copyWith(status: TaskState.loading);

    try {
      if (taskId <= 0) {
        throw ArgumentError('taskId ($taskId) must be greater than 0.');
      }

      if (newProgressId <= 0) {
        throw ArgumentError(
          'newProgressId ($newProgressId) must be greater than 0.',
        );
      }

      final projectId = ref.read(boardIdProvider);

      if (projectId == null) {
        throw StateError('No board selected');
      }

      await ref.read(tmsSyncServiceProvider).moveTaskOptimistic(
        projectId: projectId,
        taskId: taskId,
        newProgressId: newProgressId,
      );

      _setSyncMessage(ref, 'Task moved locally. Sync in progress.');
      state = state.copyWith(status: TaskState.success);
    } catch (e) {
      debugPrint('Error in reProgressTask: $e');
      state = state.copyWith(status: TaskState.error);
    }
  }

  Future<void> assignTaskToClient(String taskId, String clientId) async {
    try {
      final requestData = {'client_id': clientId};

      final response = await ApiServices.post(
        TmsURLs.assignTaskToClient(taskId),
        hasToken: true,
        data: requestData,
      );

      if (response != null &&
          (response.statusCode == 201 || response.statusCode == 200)) {
        final boardId = ref.read(boardIdProvider);

        if (boardId == null) {
          throw StateError('No board selected');
        }

        await ref
            .read(boardDetailsManagementProvider.notifier)
            .fetchBoardDetails(boardId.toString());

        _setSyncMessage(ref, 'Client assigned successfully.');
      } else {
        throw Exception('Task assign failed');
      }
    } catch (e, stack) {
      debugPrint('❌ Exception: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<dynamic> createTodoBoard(String boardName) async {
    try {
      final requestData = {'name': boardName};

      final response = await ApiServices.post(
        TmsURLs.apiTask,
        hasToken: true,
        data: requestData,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final decoded = response.data is Map<String, dynamic>
            ? response.data
            : response.data is String
                ? jsonDecode(response.data)
                : response.data is Uint8List
                    ? jsonDecode(utf8.decode(response.data))
                    : jsonDecode(utf8.decode(response.data));

        await ref.read(boardManagementProvider.notifier).fetchBoards(ref);
        _setSyncMessage(ref, 'Board created successfully.');
        return decoded;
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Exception during board creation: $e');
      return null;
    }
  }

  void _safeShowSnackBar(SnackBar snackBar) {
    try {
      final messenger = scaffoldMessengerKey.currentState;
      if (messenger == null) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(snackBar);
    } catch (e) {
      debugPrint('Snackbar skipped: $e');
    }
  }

  Future<void> editTask(
    BuildContext context,
    String taskId,
    String field,
    dynamic value,
  ) async {
    try {
      final boardId = ref.read(boardIdProvider);

      if (boardId == null) {
        throw StateError('No board selected');
      }

      await ref.read(tmsSyncServiceProvider).patchTaskOptimistic(
        projectId: boardId,
        taskId: int.parse(taskId),
        patch: {field: value},
      );

      final updatedTasks = state.tasks.map((task) {
        if (task.id.toString() == taskId) {
          return task.copyWith(
            members: field == 'members'
                ? (value as List)
                    .map((e) => int.tryParse(e.toString()) ?? 0)
                    .where((e) => e != 0)
                    .toList()
                : task.members,
            labels: field == 'labels'
                ? (value as List)
                    .map((e) => int.tryParse(e.toString()) ?? 0)
                    .where((e) => e != 0)
                    .toList()
                : task.labels,
            isCompleted:
                field == 'is_completed' ? value as bool : task.isCompleted,
            deadline: field == 'deadline' ? value : task.deadline,
            priority: field == 'priority' ? value : task.priority,
            description: field == 'description' ? value : task.description,
            name: field == 'name' ? value : task.name,
            metaFields: field == 'meta_fields' ? value : task.metaFields,
            assignedTo: field == 'assigned_to'
                ? int.tryParse(value.toString())
                : task.assignedTo,
          );
        }
        return task;
      }).toList();

      state = state.copyWith(
        status: TaskState.success,
        tasks: updatedTasks,
      );

      _setSyncMessage(ref, '$field saved locally. Sync in progress.');

      if (field != 'members') {
        _safeShowSnackBar(
          SnackBar(
            content: Text('$field updated successfully'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Exception while updating task: $e');
      debugPrintStack(stackTrace: stack);
      state = state.copyWith(status: TaskState.error);

      _safeShowSnackBar(
        SnackBar(
          content: Text('Error updating $field: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, TaskDataState>(
  (ref) => TaskNotifier(ref),
);

final taskFileProvider = StateProvider<Uint8List?>((ref) => null);

class TaskFileNotifier extends StateNotifier<List<Tasks>> {
  TaskFileNotifier(this.ref) : super([]);

  final Ref ref;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    state = List<Tasks>.from(state);
  }

  Future<void> addFileToTask(String taskId) async {
    try {
      setLoading(true);

      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();

      final String fileName = (picked.name.isNotEmpty
              ? picked.name
              : p.basename(picked.path))
          .trim()
          .replaceAll('\n', ' ')
          .replaceAll('\r', ' ');

      final String contentType =
          lookupMimeType(fileName) ?? 'application/octet-stream';

      final formData = FormData.fromMap({
        'filename': fileName,
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      });

      final response = await ApiServices.post(
        TmsURLs.addFileToTask(taskId),
        hasToken: true,
        formData: formData,
      );

      if (response != null && response.statusCode == 200) {
        await fetchTaskFiles(taskId);
        _setSyncMessage(ref, 'File uploaded successfully.');
      } else {
        if (kDebugMode) {
          debugPrint(
            '❌ Failed to add file to task. Status: ${response?.statusCode}',
          );
          debugPrint('Body: ${response?.data}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error in addFileToTask: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchTaskFiles(String taskId) async {
    try {
      final response = await ApiServices.get(
        TmsURLs.editTask(taskId),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final decodedData = _decodeMap(response.data);
        final taskDetails = Tasks.fromJson(decodedData);
        state = [taskDetails];
      } else {
        if (kDebugMode) {
          debugPrint(
            'Failed to fetch task files. Status code: ${response?.statusCode}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching task files: $e');
    }
  }

  Future<Uint8List?> pickTaskFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final Uint8List taskFile = await pickedFile.readAsBytes();
      ref.read(taskFileProvider.notifier).state = taskFile;
      return taskFile;
    }

    return null;
  }

  Future<void> deleteTask(BuildContext context, String taskId) async {
    try {
      final boardId = ref.read(boardIdProvider);
      final parsedTaskId = int.tryParse(taskId);

      if (boardId == null) {
        throw StateError('No board selected');
      }

      if (parsedTaskId == null) {
        throw StateError('Invalid task id: $taskId');
      }

      await ref.read(tmsSyncServiceProvider).deleteTaskOptimistic(
        projectId: boardId,
        taskId: parsedTaskId,
      );

      _setSyncMessage(ref, 'Task deleted locally. Sync in progress.');
    } catch (e) {
      debugPrint('❌ Error deleting task: $e');
    }
  }
  Future<void> fetchTask(String taskId) async {
    try {
      final response = await ApiServices.get(
        TmsURLs.deleteTask(taskId),
        ref: ref,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final decodedData = _decodeMap(response.data);
        final task = Tasks.fromJson(decodedData);
        state = [task];
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to fetch task. Status code: ${response?.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error fetching task: $e');
    }
  }

  void updateTask(String taskId, String field, dynamic value) {
    state = [
      for (final task in state)
        if (task.id.toString() == taskId)
          task.copyWith(
            members: field == 'members'
                ? (value as List)
                    .map((e) => int.tryParse(e.toString()) ?? 0)
                    .where((e) => e != 0)
                    .toList()
                : task.members,
            labels: field == 'labels'
                ? (value as List)
                    .map((e) => int.tryParse(e.toString()) ?? 0)
                    .where((e) => e != 0)
                    .toList()
                : task.labels,
            isCompleted:
                field == 'is_completed' ? value as bool : task.isCompleted,
            deadline: field == 'deadline' ? value : task.deadline,
            priority: field == 'priority' ? value : task.priority,
            description: field == 'description' ? value : task.description,
            name: field == 'name' ? value : task.name,
            metaFields: field == 'meta_fields' ? value : task.metaFields,
            tmsTaskChecklist: field == 'tms_task_checklist'
                ? (value as List).map((e) {
                    if (e is Map<String, dynamic>) {
                      return TaskChecklist.fromJson(e);
                    }
                    if (e is TaskChecklist) return e;
                    throw Exception('Invalid checklist item type');
                  }).toList()
                : task.tmsTaskChecklist,
            assignedTo: field == 'assigned_to'
                ? int.tryParse(value.toString())
                : task.assignedTo,
          )
        else
          task,
    ];
  }

  Future<void> addFileToTaskFromUrl(String taskId, String fileUrl) async {
    try {
      final fileResponse = await Dio().get<Uint8List>(
        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (fileResponse.statusCode == 200 && fileResponse.data != null) {
        final fileBytes = fileResponse.data!;
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            fileBytes,
            filename: 'attachment.jpg',
          ),
        });

        final response = await ApiServices.post(
          TmsURLs.addFileToTask(taskId),
          hasToken: true,
          formData: formData,
        );

        if (response != null && response.statusCode == 200) {
          debugPrint('✅ File copied to task');
          _setSyncMessage(ref, 'File copied successfully.');
        } else {
          debugPrint('❌ Failed to copy file to task: ${response?.statusCode}');
          if (response?.data != null) {
            debugPrint('❌ API error details: ${response?.data}');
          }
        }
      } else {
        debugPrint('❌ Failed to download file from URL');
      }
    } catch (e) {
      debugPrint('❌ Exception while copying file to task: $e');
      if (e is DioException) {
        debugPrint('❌ Dio error details: ${e.response?.data}');
      }
    }
  }
}

final taskDetailsProvider =
    StateNotifierProvider<TaskFileNotifier, List<Tasks>>(
  (ref) => TaskFileNotifier(ref),
);

final selectedBoardIdProvider = StateProvider<int?>((ref) => null);
final selectedColumnNameProvider = StateProvider<String?>((ref) => null);

final priorityProvider =
    StateNotifierProvider.autoDispose.family<PriorityNotifier, String, String>(
  (ref, initialPriority) => PriorityNotifier(initialPriority),
);

class PriorityNotifier extends StateNotifier<String> {
  PriorityNotifier(super.initialPriority);

  void setPriority(String priority) => state = priority;
}

final dueDateProvider =
    StateNotifierProvider.autoDispose.family<DueDateNotifier, DateTime?, DateTime?>(
  (ref, initialDate) => DueDateNotifier(initialDate),
);

class DueDateNotifier extends StateNotifier<DateTime?> {
  DueDateNotifier(super.initialDate);

  void setDueDate(DateTime? date) => state = date;
}

class DescriptionState {
  final String initialDescription;
  final String currentDescription;

  DescriptionState({
    required this.initialDescription,
    required this.currentDescription,
  });

  bool get hasChanged => currentDescription != initialDescription;

  DescriptionState copyWith({
    String? initialDescription,
    String? currentDescription,
  }) {
    return DescriptionState(
      initialDescription: initialDescription ?? this.initialDescription,
      currentDescription: currentDescription ?? this.currentDescription,
    );
  }
}

class DescriptionNotifier extends StateNotifier<DescriptionState> {
  DescriptionNotifier(String initial)
      : super(
          DescriptionState(
            initialDescription: initial,
            currentDescription: initial,
          ),
        );

  void update(String text) {
    state = state.copyWith(currentDescription: text);
  }

  void reset() {
    state = state.copyWith(currentDescription: state.initialDescription);
  }

  void save(String newText) {
    state = DescriptionState(
      initialDescription: newText,
      currentDescription: newText,
    );
  }
}

final descriptionProvider = StateNotifierProvider.autoDispose
    .family<DescriptionNotifier, DescriptionState, String?>(
  (ref, initialText) => DescriptionNotifier(initialText ?? ''),
);

final selectedMemberIdsProvider = StateProvider<List<int>>((ref) => []);
final searchMembersQueryProvider = StateProvider<String>((ref) => '');
final selectedProgressIdProvider = StateProvider<int?>((ref) => null);
final isCompleteStateProvider = StateProvider<bool>((ref) => false);
final pendingTasksProvider = StateProvider<Set<int>>((_) => <int>{});
final boardDetailsLoadingProvider = StateProvider<bool>((ref) => false);