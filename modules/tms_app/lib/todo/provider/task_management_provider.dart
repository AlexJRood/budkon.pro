// tms_app/todo/provider/task_management_provider.dart

import 'dart:convert';
import 'package:tms_app/tms_app_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:tms_app/todo/board/provider/board_details_provider.dart';
import 'package:tms_app/todo/models/tasks_model.dart';
import 'package:tms_app/todo/provider/task_filters_provider.dart';

import '../../data/default_stories_date.dart';
import '../models/board_progress_model.dart';
import '../view/model/task_model.dart';

final taskManagementProvider =
StateNotifierProvider<TaskManagementNotifier, List<ProjectProgresses>>((ref) {
  return TaskManagementNotifier(ref);
});

class TaskManagementNotifier extends StateNotifier<List<ProjectProgresses>> {
  TaskManagementNotifier(this.ref) : super([]) {
    // ✅ First load
    Future.microtask(refresh);
  }

  final Ref ref;

  /// Call this when you press "Apply" in popup
  Future<void> refresh() async {
    await fetchStories();
  }
  void syncShowAddTaskStateWithBoard() {
    final progresses =
        ref.read(boardDetailsManagementProvider).boardDetails.projectProgresses ??
            [];

    final current = ref.read(showAddTaskProvider);
    final updated = List<bool>.generate(
      progresses.length,
          (index) => index < current.length ? current[index] : false,
    );

    ref.read(showAddTaskProvider.notifier).state = updated;
  }
  onItemReorder(
      int oldItemIndex,
      int oldListIndex,
      int newItemIndex,
      int newListIndex,
      List<ProjectProgresses> storiesList,
      WidgetRef refWidget,
      ) {
    if (kDebugMode) {
      debugPrint('younis: onItemReorder');
    }
    final updatedStories = List<ProjectProgresses>.from(storiesList);
    var movedItem = updatedStories[oldListIndex].tasks?.removeAt(oldItemIndex);
    movedItem = movedItem?.copyWith(priority: updatedStories[newListIndex].name);

    final updatedTargetChildren = List<Tasks>.from(updatedStories[newListIndex].tasks ?? const [])
      ..insert(newItemIndex, movedItem!);

    updatedStories[newListIndex] =
        updatedStories[newListIndex].copyWith(tasks: updatedTargetChildren);

    if (oldListIndex != newListIndex) {
      updatedStories[oldListIndex] =
          updatedStories[oldListIndex].copyWith(tasks: List<Tasks>.from(updatedStories[oldListIndex].tasks ?? const []));
    }

    refWidget.read(taskManagementProvider.notifier).updateStories(updatedStories);
  }

  onListReorder(
      int oldListIndex,
      int newListIndex,
      List<ProjectProgresses> storiesList,
      WidgetRef refWidget,
      ) {
    if (kDebugMode) {
      debugPrint('younis: onListReorder');
    }
    if (newListIndex != storiesList.length) {
      final updatedStories = List<ProjectProgresses>.from(storiesList);
      final movedList = updatedStories.removeAt(oldListIndex);
      updatedStories.insert(newListIndex, movedList);
      refWidget.read(taskManagementProvider.notifier).updateStories(updatedStories);
    }
  }

  Future<void> columnReorder(String projectId, String columnId, int newOrder) async {
    try {
      final requestBody = {"new_order": newOrder};
      final response = await ApiServices.patch(
        TmsAppUrls.columnReorder(projectId, columnId),
        hasToken: true,
        data: requestBody,
      );
      if (response != null && response.statusCode == 200) {
        debugPrint('Column reorder done successfully');
      } else {
        debugPrint('Column reorder failed');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  int get lastTaskId {
    if (state.isEmpty) return 0;
    return state
        .expand((story) => story.tasks ?? const <Tasks>[])
        .map((task) => task.id)
        .whereType<int>()
        .fold<int>(0, (maxId, id) => id > maxId ? id : maxId);
  }

  /// ✅ IMPORTANT: This now updates state
  Future<void> fetchStories() async {
    if (kDebugMode) {
      debugPrint('Fetching stories...');
    }

    // ✅ Read filters and pass to API
    final qp = ref.read(appliedTaskFiltersProvider).toQueryParams(ref);
    if (kDebugMode) {
      debugPrint('✅ TASK FILTER QUERY PARAMS => $qp');
    }

    // start with default stories
    List<ProjectProgresses> storiesList = [];
    for (final item in defaultStories) {
      storiesList.add(ProjectProgresses.fromJson(item));
    }

    try {
      final response = await ApiServices.get(
        ref: ref,
        TmsAppUrls.apiTask,
        hasToken: true,
        queryParameters: qp,
      );

      if (kDebugMode) {
        debugPrint('Response Status Code: ${response?.statusCode}');
      }

      if (response?.statusCode == 200) {
        final responseBody =
        response?.data is Uint8List ? utf8.decode(response?.data) : response?.data;

        final jsonResponse = json.decode(responseBody);
        final List<dynamic> results = (jsonResponse['results'] as List<dynamic>? ) ?? [];

        // map API -> TaskModel
        final tasksList = results.map((taskJson) {
          return TaskModel.fromJson({
            'id': taskJson['id'],
            'name': taskJson['name'],
            'description': taskJson['name'],
            'is_completed': taskJson['is_completed'] ?? false,
            'priority': (taskJson['priority'] ?? 'Low').toString(),
            'timestamp': taskJson['timestamp'],
            'creator': taskJson['user']?['id'] ?? 0,
            'progress': taskJson['progress'] ?? 0,
            'assigned_to_user': taskJson['assigned_to_user'] ?? 0,
            'status': taskJson['status'] ?? 'Todo',
          });
        }).toList();

        // group by name (your logic)
        final taskNames = tasksList.map((t) => t.name).toSet();
        for (final taskName in taskNames) {
          final groupedTasks = tasksList.where((t) => t.name == taskName).toList();
          final mapData = {
            'title': taskName,
            'children': groupedTasks,
          };
          storiesList.add(ProjectProgresses.fromJson(mapData));
        }

        // ✅ HERE is the missing part: UPDATE STATE so UI rebuilds
        state = storiesList;
        return;
      }

      // non-200 -> still show defaults
      state = storiesList;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Error fetching stories: $error');
      }
      // show defaults if error
      state = storiesList;
    }
  }

  void updateStories(List<ProjectProgresses> updatedStories) {
    if (kDebugMode) {
      debugPrint('younis: updateStories');
    }
    state = updatedStories;
  }

  void addStory(String title) {
    if (kDebugMode) {
      debugPrint('younis: addStory');
    }
    final newStory = ProjectProgresses(name: title, tasks: []);
    if (state.every((story) => story.name != title)) {
      state = [...state, newStory];
    }
  }

  void addTaskToStory(int storyIndex, String taskName) {
    if (kDebugMode) {
      debugPrint('younis: addTaskToStory');
    }

    final updatedStories = List<ProjectProgresses>.from(state);

    if (storyIndex < updatedStories.length) {
      final story = updatedStories[storyIndex];
      final newTask = Tasks(
        id: lastTaskId + 1,
        name: taskName,
        timestamp: DateTime.now().toString(),
        description: '',
        isCompleted: false,
        priority: 'L',
        assignedToUser: 2,
      );
      final updatedTasks = List<Tasks>.from(story.tasks ?? const [])..add(newTask);

      updatedStories[storyIndex] = story.copyWith(tasks: updatedTasks);
      updateStories(updatedStories);
    }
  }
}


final showAddListProvider = StateProvider<bool>((ref) => false);
final showAddTaskProvider = StateProvider<List<bool>>((ref) => []);
