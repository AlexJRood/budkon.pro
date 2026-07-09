import 'package:crm/contact_panel/data/client_view_db_calendar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/board/provider/board_details_provider.dart';
import 'package:tms_app/todo/board/provider/board_provider.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'create_column_dialog_widget.dart';
import 'create_todo_board_dialog_widget.dart';

import 'package:get/get_utils/get_utils.dart';

final isTaskSavingProvider = StateProvider<bool>((ref) => false);

class AddTaskDialogWidget extends ConsumerWidget {
  final String clientId;
  final ScrollController? scrollController;
  const AddTaskDialogWidget({super.key, this. scrollController, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardData = ref.watch(boardManagementProvider);
    final boardDetails = ref.watch(boardDetailsManagementProvider);
    final storiesList = boardDetails.boardDetails.projectProgresses;
    final selectedBoardId = ref.watch(selectedBoardIdProvider);
    final selectedColumn = ref.watch(selectedColumnNameProvider);
    final isSaving = ref.watch(isTaskSavingProvider);
    final taskNameController = TextEditingController();
    final theme = ref.watch(themeColorsProvider);

    return Dialog(
      backgroundColor: theme.adPopBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 500.w,
        child: Padding(
          padding: const EdgeInsets.all(24),
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

              /// Board Dropdown
              boardData.results != null
                  ? DropdownButtonFormField<int>(
                value: selectedBoardId,
                dropdownColor: theme.textFieldColor,
                style:  TextStyle(color: theme.textColor),
                hint: Text(
                  'Select a board'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
                decoration:  InputDecoration(
                  filled: true,
                  fillColor: theme.textFieldColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
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
                        style:  TextStyle(color: theme.textColor),
                      ),
                    ),
                  ),
                  DropdownMenuItem<int>(
                    value: -1,
                    child: Text(
                      'Create new board'.tr,
                      style: TextStyle(color: Colors.lightBlueAccent),
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
                  ref.read(selectedColumnNameProvider.notifier).state = null;
                  if (value != null) {
                    await ref.read(boardDetailsManagementProvider.notifier)
                        .fetchBoardDetails(value.toString());
                  }
                },
              )
                  : const SizedBox.shrink(),
              const SizedBox(height: 16),

              /// Column Dropdown
              DropdownButtonFormField<String>(
                value: selectedColumn,
                dropdownColor: theme.textFieldColor,
                style:  TextStyle(color: theme.textColor),
                hint: Text(
                  'Select a column'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
                decoration:  InputDecoration(
                  filled: true,
                  fillColor: theme.textFieldColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                ),
                iconEnabledColor: theme.textColor,
                items: selectedBoardId != null && storiesList != null
                    ? [
                  ...storiesList.map(
                        (story) => DropdownMenuItem<String>(
                      value: story.name,
                      child: Text(
                        story.name!,
                        style:  TextStyle(color: theme.textColor),
                      ),
                    ),
                  ),
                  DropdownMenuItem<String>(
                    value: '__create_new_column__',
                    child: Text(
                      'Create new column'.tr,
                      style: TextStyle(color: Colors.lightBlueAccent),
                    ),
                  ),
                ]
                    : [],
                onChanged: selectedBoardId == null
                    ? null
                    : (value) async {
                  if (value == '__create_new_column__') {
                    showDialog(
                      context: context,
                      builder: (_) => CreateColumnDialogWidget(
                        selectedBoardId: selectedBoardId.toString(),
                      ),
                    );
                    return;
                  }
                  ref.read(selectedColumnNameProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 16),

              /// Task Name Input
              TextField(
                controller: taskNameController,
                style:  TextStyle(color: theme.textColor ),
                decoration: InputDecoration(
                  hintText: 'Enter task name'.tr,
                  hintStyle: TextStyle(color: theme.textColor),
                  filled: true,
                  fillColor: theme.textFieldColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// Buttons
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
                    onPressed: isSaving
                        ? null
                        : () async {
                      final boardDetails = ref.read(boardDetailsManagementProvider).boardDetails;
                      final selectedProgress = boardDetails.projectProgresses?.firstWhere(
                            (progress) => progress.name == selectedColumn,
                      );

                      if (selectedProgress == null) {
                        if (kDebugMode) print('Invalid column selected');
                        return;
                      }

                      ref.read(isTaskSavingProvider.notifier).state = true;
                      try {
                        final task = await ref.read(taskProvider.notifier).addTask(
                          taskNameController.text,
                          selectedProgress.id!,
                          selectedBoardId.toString(),
                          needMatchingItem: false,
                        );
                        final taskId = task['id'];
                        await ref.read(taskProvider.notifier).assignTaskToClient(taskId.toString(), clientId);
                        await ref.read(filterTaskByClientProvider.notifier).filterTaskByClient(clientId);
                        
                       if (!context.mounted) return;     
                        Navigator.of(context).pop();
                      } catch (e) {
                        if (kDebugMode) print('❌ Error in assignTaskToClient or addTask: $e');
                      } finally {
                        ref.read(isTaskSavingProvider.notifier).state = false;
                      }
                    },
                    child: isSaving
                        ?  SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.themeTextColor),
                      ),
                    )
                        : Text('Save'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
