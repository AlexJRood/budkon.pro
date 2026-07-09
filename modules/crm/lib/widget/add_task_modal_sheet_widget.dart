import 'package:crm/contact_panel/data/client_view_db_calendar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/board/provider/board_details_provider.dart';
import 'package:tms_app/todo/board/provider/board_provider.dart';
import 'package:tms_app/todo/models/board_progress_model.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:flutter/foundation.dart';

import 'create_column_dialog_widget.dart';
import 'create_todo_board_dialog_widget.dart';

import 'package:get/get_utils/get_utils.dart';

final isTaskSavingProvider = StateProvider<bool>((ref) => false);
final selectedColumnIdProvider = StateProvider<int?>((ref) => null);

class AddTaskModalSheetWidget extends ConsumerStatefulWidget {
  final String clientId;
  final ScrollController? scrollController;

  const AddTaskModalSheetWidget({
    super.key,
    this.scrollController,
    required this.clientId,
  });

  @override
  ConsumerState<AddTaskModalSheetWidget> createState() =>
      _AddTaskModalSheetWidgetState();
}

class _AddTaskModalSheetWidgetState
    extends ConsumerState<AddTaskModalSheetWidget> {
  late final TextEditingController taskNameController;
  late final FocusNode _taskNameFocusNode;
  final GlobalKey _taskNameFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    taskNameController = TextEditingController();
    _taskNameFocusNode = FocusNode();

    _taskNameFocusNode.addListener(() {
      if (_taskNameFocusNode.hasFocus) {
        _scrollTaskFieldIntoView();
      }
    });
  }

  @override
  void dispose() {
    taskNameController.dispose();
    _taskNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _scrollTaskFieldIntoView() async {
    if (!mounted) return;

    for (int i = 0; i < 16; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      if (MediaQuery.of(context).viewInsets.bottom > 0) {
        break;
      }
    }

    if (!mounted) return;

    final ctx = _taskNameFieldKey.currentContext;
    if (ctx == null) return;

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.15,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );

    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: 0.15,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  Future<void> _saveTask() async {
    final selectedBoardId = ref.read(selectedBoardIdProvider);
    final selectedColumnId = ref.read(selectedColumnIdProvider);
    final isSaving = ref.read(isTaskSavingProvider);

    if (isSaving) return;

    final taskName = taskNameController.text.trim();
    if (taskName.isEmpty) return;

    final boardDetails = ref.read(addTaskBoardDetailsProvider).boardDetails;

    // ✅ FIXED: safely find selected progress without using firstWhere + null
    ProjectProgresses? selectedProgress;

    for (final progress
    in boardDetails.projectProgresses ?? <ProjectProgresses>[]) {
      if (progress.id == selectedColumnId) {
        selectedProgress = progress;
        break;
      }
    }

    if (selectedProgress == null || selectedBoardId == null) {
      if (kDebugMode) {
        debugPrint('Invalid board or column selected');
      }
      return;
    }

    ref.read(isTaskSavingProvider.notifier).state = true;
    try {
      final task = await ref.read(taskProvider.notifier).addTask(
        taskName,
        selectedProgress.id!,
        selectedBoardId.toString(),
        needMatchingItem: false,
      );

      final taskId = task['id'];

      await ref.read(boardDetailsManagementProvider.notifier).fetchBoardDetails(
        ref.read(boardIdProvider).toString(),
      );

      if (widget.clientId.isNotEmpty) {
        await ref
            .read(taskProvider.notifier)
            .assignTaskToClient(taskId.toString(), widget.clientId);

        await ref
            .read(filterTaskByClientProvider.notifier)
            .filterTaskByClient(widget.clientId);
      }

      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in assignTaskToClient or addTask: $e');
      }
    } finally {
      ref.read(isTaskSavingProvider.notifier).state = false;
    }
  }
  @override
  Widget build(BuildContext context) {
    final boardData = ref.watch(boardManagementProvider);
    final boardDetails = ref.watch(addTaskBoardDetailsProvider);
    final boardDetailsState = boardDetails.state;
    final isColumnsLoading = boardDetailsState == BoardDetailsState.loading;
    final rawStoriesList = boardDetails.boardDetails.projectProgresses;
    final selectedBoardId = ref.watch(selectedBoardIdProvider);
    final selectedColumnId = ref.watch(selectedColumnIdProvider);
    final isSaving = ref.watch(isTaskSavingProvider);
    final theme = ref.watch(themeColorsProvider);

    final safeSelectedBoardId = boardData.results != null &&
        boardData.results!
            .where((board) => board.id == selectedBoardId)
            .length ==
            1
        ? selectedBoardId
        : null;

    final Map<int, dynamic> uniqueStoriesMap = {};
    if (rawStoriesList != null) {
      for (final story in rawStoriesList) {
        if (story.id != null) {
          uniqueStoriesMap[story.id!] = story;
        }
      }
    }
    final storiesList = uniqueStoriesMap.values.toList();

    final safeSelectedColumnId = selectedBoardId != null &&
        storiesList.where((story) => story.id == selectedColumnId).length ==
            1
        ? selectedColumnId
        : null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Add New Task'.tr,
              style: TextStyle(
                fontSize: 20,
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          boardData.results != null
              ? DropdownButtonFormField<int>(
            value: safeSelectedBoardId,
            dropdownColor: theme.textFieldColor,
            style: TextStyle(color: theme.textColor),
            hint: Text(
              'Select a board'.tr,
              style: TextStyle(color: theme.textColor),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.textFieldColor,
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
            ),
            iconEnabledColor: theme.textColor,
            items: [
              ...boardData.results!.map(
                    (board) => DropdownMenuItem<int>(
                  value: board.id,
                  child: Text(
                    board.name ?? 'Untitled'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ),
              DropdownMenuItem<int>(
                value: -1,
                child: Text(
                  'Create new board'.tr,
                  style: const TextStyle(color: Colors.lightBlueAccent),
                ),
              ),
            ],
            onChanged: (value) async {
              if (value == -1) {
                showDialog(
                  context: context,
                  builder: (_) => const CreateTodoBoardDialogWidget(),
                );
                return;
              }

              ref.read(selectedBoardIdProvider.notifier).state = value;
              ref.read(selectedColumnIdProvider.notifier).state = null;
              ref
                  .read(addTaskBoardDetailsProvider.notifier)
                  .resetBoardDetails();

              if (value != null) {
                await ref
                    .read(addTaskBoardDetailsProvider.notifier)
                    .fetchBoardDetails(value.toString());
              }
            },
          )
              : const SizedBox.shrink(),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: ValueKey('column_dropdown_$selectedBoardId'),
            value: safeSelectedColumnId,
            dropdownColor: theme.textFieldColor,
            style: TextStyle(color: theme.textColor),
            hint: Text(
              isColumnsLoading ? 'Loading columns...'.tr : 'Select a column'.tr,
              style: TextStyle(color: theme.textColor),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.textFieldColor,
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
            ),
            iconEnabledColor: theme.textColor,
            items: selectedBoardId != null && !isColumnsLoading
                ? [
              ...storiesList.map(
                    (story) => DropdownMenuItem<int>(
                  value: story.id,
                  child: Text(
                    story.name ?? '',
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ),
              DropdownMenuItem<int>(
                value: -999999,
                child: Text(
                  'Create new column'.tr,
                  style: const TextStyle(color: Colors.lightBlueAccent),
                ),
              ),
            ]
                : [],
            onChanged: selectedBoardId == null || isColumnsLoading
                ? null
                : (value) async {
              if (value == -999999) {
                showDialog(
                  context: context,
                  builder: (_) => CreateColumnDialogWidget(
                    selectedBoardId: selectedBoardId.toString(),
                  ),
                );
                return;
              }

              ref.read(selectedColumnIdProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 16),
          TextField(
            key: _taskNameFieldKey,
            controller: taskNameController,
            focusNode: _taskNameFocusNode,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveTask(),
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: 'Enter task name'.tr,
              hintStyle: TextStyle(color: theme.textColor),
              filled: true,
              fillColor: theme.textFieldColor,
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              disabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.themeColor,
                  foregroundColor: theme.themeTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: isSaving ? null : _saveTask,
                child: isSaving
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.themeTextColor,
                    ),
                  ),
                )
                    : Text('Save'.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }
}