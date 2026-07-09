// tms_app/todo/provider/task_checklist_provider.dart

import 'package:flutter/material.dart';
import 'package:tms_app/tms_app_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'package:tms_app/todo/models/tasks_model.dart';
import 'package:core/user/user/user_provider.dart'; // ⬅️ make sure this path matches your project

/// Notifier for server-side checklist ops (create/edit/delete)
class TaskChecklistNotifier extends StateNotifier<List<TaskChecklist>> {
  TaskChecklistNotifier(this.ref) : super([]);

  final Ref ref;

  int? get _currentUserId {
    // Adjust to your userProvider’s shape
    return ref.read(userProvider).maybeWhen(
      data: (u) => int.parse('${u?.userId}'),
      orElse: () => null,
    );
  }

  Future<void> createChecklist(
      String taskId,
      Map<String, dynamic> payload,
      ) async {
    try {
      final uid = _currentUserId;
      final body = Map<String, dynamic>.from(payload);
      // if (uid != null) {
      //   body['created_by'] = uid; // ⬅️ who created the checklist
      // }

      debugPrint('younis test Azizi');
      // ✅ Print what you’re actually sending
      debugPrint('createChecklist() -> uid: $uid');
      debugPrint('POST ${TmsAppUrls.addChecklist(taskId)}');
      debugPrint('Request body: $body'); //

      final response = await ApiServices.post(
        TmsAppUrls.addChecklist(taskId),
        data: body,
        hasToken: true,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Optionally refresh local state if needed
        // debugPrint('✅ Checklist created: ${response.data}');
      } else {
        // debugPrint('❌ Failed to create checklist: ${response?.statusCode}');
      }
    } catch (e) {
      // debugPrint('❌ Exception creating checklist: $e');
    }
  }

  /// Edit checklist and optionally annotate items with user metadata.
  ///
  /// - When adding new items, pass `isAddingItem: true` to stamp `created_by`.
  /// - When toggling an item to true, pass `toggledIndex` and `toggledValue`
  ///   to stamp `checked_by` (when `toggledValue == true`).
  Future<void> editChecklist(
      int checklistId,
      Map<String, dynamic> payload, {
        int? toggledIndex,
        bool? toggledValue,
        bool isAddingItem = false,
      }) async {
    try {
      final uid = _currentUserId;
      final body = Map<String, dynamic>.from(payload);

      // Normalize checklist array -> List<Map<String, dynamic>>
      final raw = (body['checklist'] as List?) ?? const [];
      final items = raw
          .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Stamp creator for *new* items (no id) when adding
      if (isAddingItem && uid != null) {
        for (final m in items) {
          if (!m.containsKey('id') || m['id'] == null) {
            m['created_by'] = uid; // ⬅️ who added this item
          }
        }
      }

      // Stamp checker when toggling -> true
      if (toggledIndex != null && toggledValue == true && uid != null) {
        if (toggledIndex >= 0 && toggledIndex < items.length) {
          items[toggledIndex]['checked_by'] = uid; // ⬅️ who checked it
          items[toggledIndex]['checked_at'] =
              DateTime.now().toIso8601String(); // optional
        }
      }

      body['checklist'] = items;

      final response = await ApiServices.patch(
        TmsAppUrls.editTaskChecklist(checklistId.toString()),
        data: body,
        hasToken: true,
      );

      if (response != null && response.statusCode == 200) {
        final updatedChecklist = TaskChecklist.fromJson(response.data);
        state = [
          for (final item in state)
            if (item.id == checklistId) updatedChecklist else item,
        ];
      } else {
        // debugPrint('❌ Failed to edit checklist');
      }
    } catch (e) {
      // debugPrint('❌ Error editing checklist: $e');
    }
  }

  Future<void> deleteCheckList(String checklistId) async {
    try {
      final response = await ApiServices.delete(
        TmsAppUrls.editTaskChecklist(checklistId),
        hasToken: true,
      );
      if (response != null && response.statusCode == 204) {
        // debugPrint('Checklist deleted successfully');
      } else {
        // debugPrint('Checklist delete failed');
      }
    } catch (e) {
      // debugPrint(e);
    }
  }
}

final taskChecklistProvider =
StateNotifierProvider<TaskChecklistNotifier, List<TaskChecklist>>(
      (ref) => TaskChecklistNotifier(ref),
);

/// -------- Local UI state for items (unchanged) --------

class ChecklistState {
  final List<ChecklistItem> items;
  final bool isAdding;

  ChecklistState({required this.items, this.isAdding = false});

  ChecklistState copyWith({List<ChecklistItem>? items, bool? isAdding}) {
    return ChecklistState(
      items: items ?? this.items,
      isAdding: isAdding ?? this.isAdding,
    );
  }
}

class ChecklistNotifier extends StateNotifier<ChecklistState> {
  ChecklistNotifier(List<ChecklistItem> initialItems)
      : super(ChecklistState(items: initialItems));

  void toggleComplete(int index, bool? value) {
    final updated = [...state.items];
    updated[index] = updated[index].copyWith(completed: value ?? false);
    state = state.copyWith(items: updated);
  }

  void addItem(String title) {
    if (title.trim().isEmpty) return;
    final updated = [
      ...state.items,
      ChecklistItem(name: title, completed: false),
    ];
    // keep add row open in the UI – the widget controls visibility
    state = state.copyWith(items: updated);
  }

  void setAdding(bool adding) {
    state = state.copyWith(isAdding: adding);
  }
}

final checklistProvider = StateNotifierProvider.family<
    ChecklistNotifier,
    ChecklistState,
    List<ChecklistItem>>(
      (ref, initialItems) => ChecklistNotifier(initialItems),
);
