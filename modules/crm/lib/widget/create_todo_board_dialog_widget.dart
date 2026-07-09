import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:tms_app/todo/board/provider/board_details_provider.dart';
import 'package:tms_app/todo/board/provider/board_provider.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:get/get_utils/get_utils.dart';

final createBoardLoadingProvider = StateProvider<bool>((ref) => false);

class CreateTodoBoardDialogWidget extends ConsumerStatefulWidget {
  const CreateTodoBoardDialogWidget({super.key});

  @override
  ConsumerState<CreateTodoBoardDialogWidget> createState() =>
      _CreateTodoBoardDialogWidgetState();
}

class _CreateTodoBoardDialogWidgetState
    extends ConsumerState<CreateTodoBoardDialogWidget> {
  final TextEditingController boardNameController = TextEditingController();
  bool isValid = false;

  @override
  void initState() {
    super.initState();
    boardNameController.addListener(() {
      final textNotEmpty = boardNameController.text.trim().isNotEmpty;
      if (textNotEmpty != isValid) {
        setState(() {
          isValid = textNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    boardNameController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(createBoardLoadingProvider);
    final theme = ref.watch(themeColorsProvider);

    return Dialog(
      backgroundColor: theme.dashboardContainer,
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
                  'Create New Board'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: boardNameController,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Board Name'.tr,
                  hintStyle: TextStyle(color: theme.textColor),
                  filled: true,
                  fillColor: theme.textFieldColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.bordercolor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.bordercolor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.bordercolor),
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
                      backgroundColor: isValid ? theme.themeColor : theme.themeColor.withAlpha((255 * 0.7).toInt()),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: isLoading || !isValid
                        ? null
                        : () async {
                      final boardName = boardNameController.text.trim();
                      if (boardName.isNotEmpty) {
                        ref.read(createBoardLoadingProvider.notifier).state =
                        true;

                        final newBoard = await ref
                            .read(taskProvider.notifier)
                            .createTodoBoard(boardName);

                        if (newBoard != null && newBoard['id'] != null) {
                          final newBoardId = newBoard['id'] as int;
                          await ref
                              .read(boardManagementProvider.notifier)
                              .fetchBoards(ref);
                          ref
                              .read(selectedBoardIdProvider.notifier)
                              .state = newBoardId;
                          await ref
                              .read(boardDetailsManagementProvider.notifier)
                              .fetchBoardDetails(newBoardId.toString());
                        }

                        ref
                            .read(createBoardLoadingProvider.notifier)
                            .state = false;

                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      }
                    },
                    child: isLoading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text('Save'.tr,
                    style: AppTextStyles.interMedium.copyWith(
                      color: theme.themeTextColor
                    ),),
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
