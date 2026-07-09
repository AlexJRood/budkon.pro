// tms_app/todo/provider/task_labels_provider.dart

import 'package:flutter/cupertino.dart';
import 'package:tms_app/tms_app_urls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/api_services.dart';
import 'dart:convert';

import 'package:tms_app/todo/view/model/task_label_model.dart';

final taskLabelsProvider =
    StateNotifierProvider<TaskLabelsNotifier, TaskLabelsResponse?>(
      (ref) => TaskLabelsNotifier(ref),
    );

final labelColorProvider = StateProvider<String?>((ref) => null);
final labelNameProvider = StateProvider<String>((ref) => '');

class TaskLabelsNotifier extends StateNotifier<TaskLabelsResponse?> {
  final Ref ref;
  TaskLabelsNotifier(this.ref) : super(null);

  Future<void> fetchLabels() async {
    try {
      final response = await ApiServices.get(
        TmsAppUrls.taskLabels,
        ref: ref,
        hasToken: true,
      );
      if (response != null && response.statusCode == 200) {
        final decoded = utf8.decode(response.data);
        final json = jsonDecode(decoded);
        state = TaskLabelsResponse.fromJson(json);
      } else {
        debugPrint('failed to load labels');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> addLabel(String name, String color) async {
    try {
      final response = await ApiServices.post(
        TmsAppUrls.taskLabels,
        hasToken: true,
        data: {"name": name, "color": color},
      );

      if (response != null && response.statusCode == 201) {
        final label = TaskLabel.fromJson(response.data);
        final current = state?.results ?? [];
        state = TaskLabelsResponse(
          count: (state?.count ?? 0) + 1,
          next: state?.next,
          previous: state?.previous,
          results: [...current, label],
        );
      } else {
        debugPrint('failed to create label');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> editLabel({
    required String labelId,
    required String name,
    required String color,
  }) async {
    try {
      final response = await ApiServices.patch(
        TmsAppUrls.editTaskLabel(labelId),
        hasToken: true,
        data: {'name': name, 'color': color},
      );
      if (response != null && response.statusCode == 200) {
        debugPrint('✅ Label edited successfully: ${response.data}');
        fetchLabels();
      } else {
        debugPrint('❌ Error editing label: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Exception editing label: $e');
    }
  }

  Future<void> deleteLabel(String labelId) async {
    try {
      final response = await ApiServices.delete(
        TmsAppUrls.editTaskLabel(labelId),
        hasToken: true,
      );

      if (response != null && response.statusCode == 204) {
        debugPrint('Label deleted successfully');
        fetchLabels();
      } else {
        debugPrint('Deleting label failed');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

final searchLabelQueryProvider = StateProvider<String>((ref) => '');
// final selectedLabelIdsProvider = StateProvider<List<int>>((ref) => []);

final filteredLabelsProvider = Provider<List<TaskLabel>>((ref) {
  final query = ref.watch(searchLabelQueryProvider).toLowerCase();
  final labels = ref.watch(taskLabelsProvider)?.results ?? [];
  if (query.isEmpty) return labels;
  return labels
      .where((label) => label.name.toLowerCase().contains(query))
      .toList();
});

final triedSubmitProvider = StateProvider.autoDispose<bool>((_) => false);
final prefilledProvider = StateProvider.autoDispose<bool>((_) => false);
final fetchGuardProvider = StateProvider.autoDispose<bool>((_) => false);
final pickerColorProvider = StateProvider.autoDispose<HSVColor>(
  (ref) => const HSVColor.fromAHSV(1, 120, 1, 1),
);
final pickerHexProvider = StateProvider.autoDispose<String>((ref) => '#61BD4F');
final pickerInitDoneProvider = StateProvider.autoDispose<bool>((ref) => false);

final pickerHexTextControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final ctrl = TextEditingController();
      ref.onDispose(ctrl.dispose);
      return ctrl;
    });
