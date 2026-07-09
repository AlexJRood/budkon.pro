import 'dart:convert';
import 'package:crm_fliper/crm_fliper_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_fliper/refurbishment/models/reforbishment_tasks_response_model.dart';
import 'package:crm_fliper/refurbishment/models/refurbishment_progress_model.dart';
import 'package:crm_fliper/refurbishment/models/refurbishment_progress_response_model.dart';
import 'package:crm_fliper/refurbishment/models/refurbishment_task_model.dart';
import 'package:core/platform/api_services.dart';
import 'package:flutter/foundation.dart';

class RefurbishmentTasksNotifier
    extends StateNotifier<List<RefurbishmentTask>> {
  RefurbishmentTasksNotifier() : super([]);

  Future<void> refurbishmentFetchTask(dynamic ref) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.refurbishmentFetchTasks,
        ref: ref,
        hasToken: true,
      );
      if (response != null && response.statusCode == 200) {
        final responseString = utf8.decode(response.data);
        final jsonResponse = jsonDecode(responseString);
        final tasksResponse = RefurbishmentTasksResponse.fromJson(jsonResponse);
        state = tasksResponse.results;
        if (kDebugMode) {
          debugPrint(
            'Refurbishment tasks fetched successfully. Task count: ${state.length}');
        }
        for (var task in state) {
          if (kDebugMode) {
            debugPrint(
              'Task ID: ${task.id}, Name: ${task.taskNameDisplay}, Budget: ${task.budget}');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            'Refurbishment tasks fetch failed. Status code: ${response?.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching tasks: $e');
    }
  }

  Future<void> refurbishmentCreateTask(dynamic ref) async {
    try {
      final body = {
        "id": 2,
        "transaction": 1,
        "task_name": "PLANNING",
        "task_name_display": "Planning",
        "budget": "5000.00",
        "actual_cost": null
      };
      final response = await ApiServices.post(CrmFliperUrls.refurbishmentCreateTask,
          hasToken: true, data: body);
      if (response != null && response.statusCode == 201 ||
          response?.statusCode == 200) {
        if (kDebugMode) debugPrint('Refurbishment task created successfully');
        await refurbishmentFetchTask(ref);
      } else {
        if (kDebugMode) {
          debugPrint(
            'Refurbishment task creation failed. Status code: ${response?.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating task: $e');
    }
  }
}

final refurbishmentTaskProvider =
    StateNotifierProvider<RefurbishmentTasksNotifier, List<RefurbishmentTask>>(
  (ref) => RefurbishmentTasksNotifier(),
);

class RefurbishmentProgressNotifier
    extends StateNotifier<List<RefurbishmentProgress>> {
  RefurbishmentProgressNotifier() : super([]);

  Future<void> refurbishmentFetchProgress(dynamic ref) async {
    try {
      final response = await ApiServices.get(
        CrmFliperUrls.refurbishmentFetchProgress,
        ref: ref,
        hasToken: true,
      );
      if (response != null && response.statusCode == 200) {
        final responseString = utf8.decode(response.data);
        final jsonResponse = jsonDecode(responseString);
        final progressResponse =
            RefurbishmentProgressResponse.fromJson(jsonResponse);
        state = progressResponse.results;
        if (kDebugMode) {
          debugPrint(
            'Refurbishment progress fetched successfully. Count: ${state.length}');
        }
        for (var progress in state) {
          if (kDebugMode) {
            debugPrint(
              'Progress ID: ${progress.id}, Task: ${progress.task}, Status: ${progress.status}');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            'Refurbishment progress fetch failed. Status code: ${response?.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching progress: $e');
    }
  }

  Future<void> refurbishmentCreateProgress(dynamic ref) async {
    try {
      final body = {
        "id": 1,
        "task": 1,
        "planned_start_date": "2025-01-01",
        "planned_end_date": "2025-01-05",
        "actual_start_date": "2025-01-02",
        "actual_end_date": null,
        "status": "IN_PROGRESS"
      };
      final response = await ApiServices.post(CrmFliperUrls.refurbishmentCreateProgress,
          hasToken: true, data: body);
      if (response != null && response.statusCode == 201 ||
          response?.statusCode == 200) {
        if (kDebugMode) debugPrint('Refurbishment progress created successfully');
        await refurbishmentFetchProgress(ref);
      } else {
        if (kDebugMode) {
          debugPrint(
            'Refurbishment progress creation failed. Status code: ${response?.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating task: $e');
    }
  }
}

final refurbishmentProgressProvider = StateNotifierProvider<
    RefurbishmentProgressNotifier, List<RefurbishmentProgress>>(
  (ref) => RefurbishmentProgressNotifier(),
);
