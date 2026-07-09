import 'package:crm/widget/create_todo_board_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/lottie.dart';

import 'package:tms_app/todo/board/provider/board_details_provider.dart';
import 'package:tms_app/todo/board/provider/board_provider.dart';
import 'package:tms_app/todo/models/board_progress_model.dart';
import 'package:tms_app/todo/models/board_details_model.dart';
import 'package:tms_app/todo/provider/move_task_provider.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';

class MoveTaskWidget extends ConsumerStatefulWidget {
  final String taskId;
  const MoveTaskWidget({super.key, required this.taskId});

  @override
  ConsumerState<MoveTaskWidget> createState() => _MoveTaskWidgetState();
}

class _MoveTaskWidgetState extends ConsumerState<MoveTaskWidget> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(boardManagementProvider.notifier).fetchBoards(ref);
      ref.invalidate(boardsListProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final scope = ref.watch(moveScopeProvider);

    final currentBoard = ref.watch(boardDetailsStateProvider);
    final progresses =
        currentBoard.projectProgresses ?? const <ProjectProgresses>[];

    final withinTarget = ref.watch(withinBoardTargetProgressProvider);
    final targetBoard = ref.watch(targetBoardProvider);
    final otherBoardAsync = ref.watch(otherBoardDetailsProvider);
    final otherTarget = ref.watch(otherBoardTargetProgressProvider);

    final canSubmit =
        scope == MoveScope.withinBoard
            ? withinTarget != null
            : (otherBoardAsync.value != null && otherTarget != null);

    return Dialog(
      backgroundColor: theme.adPopBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 460,
        height: 560,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Move Task'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    backgroundColor: theme.adPopBackground,
                    selectedColor: theme.themeColor,
                    selected: scope == MoveScope.withinBoard,
                    checkmarkColor:
                        scope == MoveScope.withinBoard
                            ? theme.themeTextColor
                            : theme.textColor,
                    label: Text(
                      'This board'.tr,
                      style: AppTextStyles.interMedium.copyWith(
                        color:
                            scope == MoveScope.withinBoard
                                ? theme.themeTextColor
                                : theme.textColor,
                      ),
                    ),
                    onSelected:
                        (_) =>
                            ref.read(moveScopeProvider.notifier).state =
                                MoveScope.withinBoard,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    backgroundColor: theme.adPopBackground,
                    selectedColor: theme.themeColor,
                    selected: scope == MoveScope.anotherBoard,
                    checkmarkColor:
                        scope == MoveScope.anotherBoard
                            ? theme.themeTextColor
                            : theme.textColor,
                    label: Text(
                      'Another board'.tr,
                      style: AppTextStyles.interMedium.copyWith(
                        color:
                            scope == MoveScope.anotherBoard
                                ? theme.themeTextColor
                                : theme.textColor,
                      ),
                    ),
                    onSelected:
                        (_) =>
                            ref.read(moveScopeProvider.notifier).state =
                                MoveScope.anotherBoard,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child:
                  scope == MoveScope.withinBoard
                      ? _WithinBoardList(progresses: progresses)
                      : _AnotherBoardPicker(
                        targetBoard: targetBoard,
                        otherBoardAsync: otherBoardAsync,
                      ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
                backgroundColor: canSubmit ? theme.themeColor : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed:
                  !canSubmit
                      ? null
                      : () async {
                        if (scope == MoveScope.withinBoard) {
                          await _moveWithinBoard(context, ref);
                        } else {
                          await _moveToAnotherBoard(context, ref);
                        }
                      },
              child: Text(
                scope == MoveScope.withinBoard ? 'Move'.tr : 'Move to board'.tr,
                style: TextStyle(color: theme.themeTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveWithinBoard(BuildContext context, WidgetRef ref) async {
    final progressId = ref.read(withinBoardTargetProgressProvider);
    if (progressId == null) return;

    await ref
        .read(taskProvider.notifier)
        .reProgressTask(int.parse(widget.taskId), progressId);

    await ref
        .read(boardDetailsManagementProvider.notifier)
        .fetchBoardDetails(ref.read(boardIdProvider).toString());

    if (!context.mounted) return;
    Navigator.pop(context);

    final board = ref.read(boardDetailsStateProvider);
    final name =
        (board.projectProgresses ?? const [])
            .firstWhere(
              (p) => p.id == progressId,
              orElse: () => ProjectProgresses(),
            )
            .name ??
        '';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('✅ ${"Task moved to".tr} "$name"')));
  }

  Future<void> _moveToAnotherBoard(BuildContext context, WidgetRef ref) async {
    final otherBoard = ref.read(otherBoardDetailsProvider).value;
    final progressId = ref.read(otherBoardTargetProgressProvider);
    if (otherBoard == null || progressId == null) return;

    await ref
        .read(taskProvider.notifier)
        .moveTaskToAnotherBoard(
          taskId: int.parse(widget.taskId),
          targetProjectId: otherBoard.id!,
          targetProgressId: progressId,
        );

    await ref
        .read(boardDetailsManagementProvider.notifier)
        .fetchBoardDetails(ref.read(boardIdProvider).toString());

    if (!context.mounted) return;
    Navigator.pop(context);

    final progressName =
        (otherBoard.projectProgresses ?? const [])
            .firstWhere(
              (p) => p.id == progressId,
              orElse: () => ProjectProgresses(),
            )
            .name ??
        '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ ${"Task moved to Board".tr} #${otherBoard.id} → "$progressName"',
        ),
      ),
    );
  }
}

class _WithinBoardList extends ConsumerWidget {
  const _WithinBoardList({required this.progresses});
  final List<ProjectProgresses> progresses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final selectedId = ref.watch(withinBoardTargetProgressProvider);

    return ListView.builder(
      addAutomaticKeepAlives: false,
      cacheExtent: 300.0,
      itemCount: progresses.length,
      itemBuilder: (_, index) {
        final p = progresses[index];
        final isSelected = selectedId == p.id;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: InkWell(
            onTap:
                () =>
                    ref.read(withinBoardTargetProgressProvider.notifier).state =
                        p.id,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? theme.themeColor.withValues(alpha: 0.1)
                        : theme.textFieldColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.themeColor)
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name ?? 'Unnamed'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: theme.themeColor, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnotherBoardPicker extends ConsumerWidget {
  const _AnotherBoardPicker({
    required this.targetBoard,
    required this.otherBoardAsync,
  });

  final SimpleBoard? targetBoard;
  final AsyncValue<BoardDetailsModel?> otherBoardAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final boardsAsync = ref.watch(boardsListProvider);
    final pickedProgressId = ref.watch(otherBoardTargetProgressProvider);
    final currentBoardId = ref.watch(boardIdProvider);
    final dropDownBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: theme.themeColor),
    );

    Future<void> openCreateBoard() async {
      await showDialog(
        context: context,
        builder: (_) => const CreateTodoBoardDialogWidget(),
      );
      ref.invalidate(boardsListProvider);
      ref.read(targetBoardProvider.notifier).state = null;
      ref.read(otherBoardTargetProgressProvider.notifier).state = null;
    }

    return Column(
      children: [
        boardsAsync.when(
          loading: () => Expanded(child: Center(child: AppLottie.loading())),
          error:
              (e, _) => Expanded(
                child: Center(
                  child: Text(
                    '${"Error loading boards:".tr} $e',
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ),
          data: (boards) {
            final others = boards.where((b) => b.id != currentBoardId).toList();

            if (others.isEmpty) {
              return Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.dashboard_customize,
                        size: 36,
                        color: theme.textColor.withValues(alpha: .7),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No other boards yet'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create a board to move tasks there'.tr,
                        style: TextStyle(
                          color: theme.textColor.withValues(alpha: .75),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.themeColor,
                          foregroundColor: theme.themeTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: openCreateBoard,
                        label:  Text('Create board'.tr),
                      ),
                    ],
                  ),
                ),
              );
            }

            final safeValue = targetBoard == null
                ? null
                : others.firstWhereOrNull((b) => b.id == targetBoard!.id);

            return Column(
              children: [
                SizedBox(
                  height: 44,
                  child: DropdownButtonFormField<SimpleBoard>(
                    menuMaxHeight: 200,
                    alignment: Alignment.centerLeft,
                    value: safeValue,
                    isExpanded: true,
                    dropdownColor: theme.adPopBackground,

                    hint: Text(
                      'Select a board'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 14,
                        height: 1,
                      ),
                    ),

                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 14,
                      height: 1,
                    ),

                    items: others.map((b) {
                      return DropdownMenuItem<SimpleBoard>(
                        value: b,
                        child: Text(
                          b.name,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 14,
                            height: 1,
                          ),
                        ),
                      );
                    }).toList(),

                    decoration: InputDecoration(
                      isDense: false,
                      filled: true,
                      fillColor: theme.textFieldColor,
                      contentPadding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 0,
                        bottom: 0,
                      ),
                      border: dropDownBorderStyle,
                      enabledBorder: dropDownBorderStyle,
                      focusedBorder: dropDownBorderStyle,
                      disabledBorder: dropDownBorderStyle,
                    ),

                    onChanged: (b) {
                      ref.read(targetBoardProvider.notifier).state = b;
                      ref.read(otherBoardTargetProgressProvider.notifier).state = null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: openCreateBoard,
                    icon:  Icon(Icons.add,color: theme.textColor,),
                    label:  Text('New board'.tr),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.textColor,
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 12),

        otherBoardAsync.when(
          loading: () => Expanded(child: Center(child: AppLottie.loading())),
          error:
              (e, _) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${"Failed to load columns:".tr} $e',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
          data: (otherBoard) {
            if (otherBoard == null) {
              return Expanded(
                child: Center(
                  child: Text(
                    'Select a board to load its columns'.tr,
                    style: TextStyle(
                      color: theme.textColor.withValues(alpha: .7),
                    ),
                  ),
                ),
              );
            }

            final cols =
                otherBoard.projectProgresses ?? const <ProjectProgresses>[];
            return Expanded(
              child: ListView.builder(
                addAutomaticKeepAlives: false,
                cacheExtent: 300.0,
                itemCount: cols.length,
                itemBuilder: (_, i) {
                  final p = cols[i];
                  final isSelected = pickedProgressId == p.id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: InkWell(
                      onTap:
                          () =>
                              ref
                                  .read(
                                    otherBoardTargetProgressProvider.notifier,
                                  )
                                  .state = p.id!,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? theme.themeColor.withValues(alpha: 0.1)
                                  : theme.textFieldColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.name ?? 'Unnamed'.tr,
                                style: TextStyle(color: theme.textColor),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: theme.themeColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
