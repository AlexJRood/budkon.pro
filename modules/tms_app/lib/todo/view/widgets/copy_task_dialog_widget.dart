import 'dart:convert' as convert;
import 'package:collection/collection.dart';
import 'package:crm/widget/create_todo_board_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/lottie.dart';
import 'package:tms_app/todo/provider/copy_task_provider.dart';
import 'package:tms_app/todo/provider/move_task_provider.dart'
    hide targetBoardProvider;
import 'package:core/user/user/user_provider.dart';
import 'package:tms_app/todo/models/board_progress_model.dart';
import 'package:tms_app/todo/board/provider/board_details_provider.dart';
import 'package:tms_app/todo/board/provider/board_provider.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';

class CopyTaskWidget extends ConsumerStatefulWidget {
  final String taskId;
  const CopyTaskWidget({super.key, required this.taskId});

  @override
  ConsumerState<CopyTaskWidget> createState() => _CopyTaskWidgetState();
}

class _CopyTaskWidgetState extends ConsumerState<CopyTaskWidget> {

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

    final scope = ref.watch(copyScopeProvider);
    final currentBoard = ref.watch(boardDetailsStateProvider);
    final progresses =
        currentBoard.projectProgresses ?? const <ProjectProgresses>[];

    final selectedProgressInThisBoard = ref.watch(selectedProgressIdProvider);

    final boardsAsync = ref.watch(boardsListProvider);
    final pickedBoard = ref.watch(targetBoardProvider);
    final pickedOtherProgressId = ref.watch(targetProgressIdProvider);

    Widget body;
    if (scope == CopyScope.withinBoard) {
      body = _WithinBoardList(
        theme: theme,
        progresses: progresses,
        selectedId: selectedProgressInThisBoard,
        onPick:
            (id) => ref.read(selectedProgressIdProvider.notifier).state = id,
      );
    } else {
      body = boardsAsync.when(
        loading: () => Center(child: AppLottie.loading()),
        error:
            (e, _) => Center(
              child: Text(
                'Error loading boards: $e',
                style: TextStyle(color: theme.textColor),
              ),
            ),
        data:
            (boards) => _AnotherBoardPicker(
              theme: theme,
              boards: boards,
              pickedBoard: pickedBoard,
              onPickBoard: (b) {
                ref.read(targetBoardProvider.notifier).state = b;
                ref.read(targetProgressIdProvider.notifier).state = null;
              },
              pickedProgressId: pickedOtherProgressId,
            ),
      );
    }

    final canSubmit =
        scope == CopyScope.withinBoard
            ? selectedProgressInThisBoard != null
            : (pickedBoard != null && pickedOtherProgressId != null);

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
              'Copy Task'.tr,
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
                    selected: scope == CopyScope.withinBoard,
                    checkmarkColor:
                        scope == CopyScope.withinBoard
                            ? theme.themeTextColor
                            : theme.textColor,
                    label: Text(
                      'This board'.tr,
                      style: AppTextStyles.interMedium.copyWith(
                        color:
                            scope == CopyScope.withinBoard
                                ? theme.themeTextColor
                                : theme.textColor,
                      ),
                    ),
                    onSelected:
                        (_) =>
                            ref.read(copyScopeProvider.notifier).state =
                                CopyScope.withinBoard,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    backgroundColor: theme.adPopBackground,
                    selectedColor: theme.themeColor,
                    selected: scope == CopyScope.anotherBoard,
                    checkmarkColor:
                        scope == CopyScope.anotherBoard
                            ? theme.themeTextColor
                            : theme.textColor,
                    label: Text(
                      'Another board'.tr,
                      style: AppTextStyles.interMedium.copyWith(
                        color:
                            scope == CopyScope.anotherBoard
                                ? theme.themeTextColor
                                : theme.textColor,
                      ),
                    ),
                    onSelected:
                        (_) =>
                            ref.read(copyScopeProvider.notifier).state =
                                CopyScope.anotherBoard,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: body),
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
                        if (scope == CopyScope.withinBoard) {
                          await _copyWithinBoard(context, ref, widget.taskId);
                        } else {
                          await _copyToAnotherBoard(context, ref, widget.taskId);
                        }
                      },
              child: Text(
                'Copy'.tr,
                style: TextStyle(color: theme.themeTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyWithinBoard(
    BuildContext context,
    WidgetRef ref,
    String taskId,
  ) async {
    final currentBoard = ref.read(boardDetailsStateProvider);
    final progresses =
        currentBoard.projectProgresses ?? const <ProjectProgresses>[];

    final selectedProgressId = ref.read(selectedProgressIdProvider);
    if (selectedProgressId == null) return;

    final allTasks = ref.read(taskDetailsProvider);
    final task = allTasks.firstWhereOrNull((t) => t.id.toString() == taskId);

    if (task == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar( SnackBar(content: Text('Task not found'.tr)));
        Navigator.pop(context);
      }
      return;
    }

    final userId = ref.read(userProvider).value?.userId;
    final projectId = currentBoard.id?.toString();
    if (projectId == null) return;

    final newTaskName = '${task.name} (${"Copy".tr})';

    final payload = {
      "project": projectId,
      "name": newTaskName,
      "description": task.description ?? '',
      "priority": task.priority ?? 'M',
      "meta_fields": _safeMeta(task.metaFields),
      "progress": selectedProgressId,
      "user": userId,
      "members": task.members ?? [],
      "deadline": task.deadline,
      "label": task.labels ?? [],
    };

    final created = await ref.read(taskProvider.notifier).addTaskFull(payload);
    final createdId = _extractId(created);
    if (createdId == null) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar( SnackBar(content: Text('❌ Failed to copy task'.tr)));
      }
      return;
    }

    final attachments = task.files ?? [];
    for (final f in attachments) {
      if (f.file != null && f.file!.isNotEmpty) {
        await ref
            .read(taskDetailsProvider.notifier)
            .addFileToTaskFromUrl(createdId.toString(), f.file!);
      }
    }

    await ref
        .read(boardDetailsManagementProvider.notifier)
        .fetchBoardDetails(ref.read(boardIdProvider).toString());

    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      final progressName =
          progresses
              .firstWhereOrNull((p) => p.id == selectedProgressId)
              ?.name ??
          '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${"Task copied to".tr} "$progressName"')),
      );
    }
  }

  Future<void> _copyToAnotherBoard(
    BuildContext context,
    WidgetRef ref,
    String taskId,
  ) async {
    final pickedBoard = ref.read(targetBoardProvider);
    final pickedProgressId = ref.read(targetProgressIdProvider);
    if (pickedBoard == null || pickedProgressId == null) return;

    final allTasks = ref.read(taskDetailsProvider);
    final task = allTasks.firstWhereOrNull((t) => t.id.toString() == taskId);

    if (task == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar( SnackBar(content: Text('Task not found'.tr)));
        Navigator.pop(context);
      }
      return;
    }

    final userId = ref.read(userProvider).value?.userId;
    final newTaskName = '${task.name} (${"Copy".tr})';

    final payload = {
      "project": pickedBoard.id.toString(),
      "name": newTaskName,
      "description": task.description ?? '',
      "priority": task.priority ?? 'M',
      "meta_fields": _safeMeta(task.metaFields),
      "progress": pickedProgressId,
      "user": userId,
      "members": task.members ?? [],
      "deadline": task.deadline,
      "label": task.labels ?? [],
    };

    final created = await ref.read(taskProvider.notifier).addTaskFull(payload);
    final createdId = _extractId(created);
    if (createdId == null) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar( SnackBar(content: Text('❌ Failed to copy task'.tr)));
      }
      return;
    }

    final attachments = task.files ?? [];
    for (final f in attachments) {
      if (f.file != null && f.file!.isNotEmpty) {
        await ref
            .read(taskDetailsProvider.notifier)
            .addFileToTaskFromUrl(createdId.toString(), f.file!);
      }
    }

    await ref
        .read(boardDetailsManagementProvider.notifier)
        .fetchBoardDetails(ref.read(boardIdProvider).toString());

    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      final other = await ref.read(
        boardDetailsByIdProvider(pickedBoard.id).future,
      );
      final progressName =
          other?.projectProgresses
              ?.firstWhereOrNull((p) => p.id == pickedProgressId)
              ?.name ??
          '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${"Task copied to".tr} ${pickedBoard.name} → "$progressName"',
          ),
        ),
      );
    }
  }

  int? _extractId(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      final d = data;
      final id = d['id'] ?? (d['data'] is Map ? d['data']['id'] : null);
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
    }
    if (data is String) {
      try {
        final j = convert.jsonDecode(data);
        return _extractId(j);
      } catch (_) {}
    }
    if (data is List<int>) {
      try {
        final j = convert.jsonDecode(convert.utf8.decode(data));
        return _extractId(j);
      } catch (_) {}
    }
    return null;
  }

  Map<String, dynamic> _safeMeta(dynamic metaFields) {
    try {
      if (metaFields == null) return {};
      if (metaFields is Map<String, dynamic>) return metaFields;
      final toJson = (metaFields as dynamic).toJson;
      if (toJson is Function) {
        final m = toJson();
        if (m is Map<String, dynamic>) return m;
      }
    } catch (_) {}
    return {};
  }
}

class _WithinBoardList extends StatelessWidget {
  final ThemeColors theme;
  final List<ProjectProgresses> progresses;
  final int? selectedId;
  final ValueChanged<int?> onPick;

  const _WithinBoardList({
    required this.theme,
    required this.progresses,
    required this.selectedId,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      addAutomaticKeepAlives: false,
      cacheExtent: 300.0,
      itemCount: progresses.length,
      itemBuilder: (_, index) {
        final progress = progresses[index];
        final isSelected = selectedId == progress.id;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: InkWell(
            onTap: () => onPick(progress.id),
            child: Container(
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? theme.themeColor.withValues(alpha: 0.1)
                        : theme.textFieldColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.themeColor)
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      progress.name ?? 'Unnamed'.tr,
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
  final ThemeColors theme;
  final List<SimpleBoard> boards;
  final SimpleBoard? pickedBoard;
  final ValueChanged<SimpleBoard> onPickBoard;

  final int? pickedProgressId;

  const _AnotherBoardPicker({
    required this.theme,
    required this.boards,
    required this.pickedBoard,
    required this.onPickBoard,
    required this.pickedProgressId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBoardId = ref.watch(boardIdProvider);
    final others = boards.where((b) => b.id != currentBoardId).toList();
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
      ref.read(targetProgressIdProvider.notifier).state = null;
    }

    final effectiveBoard = pickedBoard == null
        ? null
        : others.firstWhereOrNull((b) => b.id == pickedBoard!.id);

    final detailsAsync =
        effectiveBoard == null
            ? null
            : ref.watch(boardDetailsByIdProvider(effectiveBoard.id));

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
                'Create a board to copy tasks there'.tr,
                style: TextStyle(color: theme.textColor.withValues(alpha: .75)),
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

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: DropdownButtonFormField<SimpleBoard>(
            menuMaxHeight: 200,
            alignment: Alignment.centerLeft,
            value: effectiveBoard,
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

            items: others
                .map(
                  (b) => DropdownMenuItem<SimpleBoard>(
                value: b,
                child: Text(
                  b.name,
                  style:  TextStyle(
                    color: theme.textColor,
                    fontSize: 14,
                    height: 1
                  ),
                ),
              ),
            )
                .toList(),
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
              disabledBorder: dropDownBorderStyle,
              focusedBorder: dropDownBorderStyle,
            ),
            onChanged: (b) {
              if (b != null) onPickBoard(b);
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
            style: TextButton.styleFrom(foregroundColor: theme.textColor),
          ),
        ),
        const SizedBox(height: 8),

        if (detailsAsync == null)
          Expanded(
            child: Center(
              child: Text(
                'Select a board to load its columns'.tr,
                style: TextStyle(color: theme.textColor.withValues(alpha: .7)),
              ),
            ),
          )
        else
          detailsAsync.when(
            loading: () => Expanded(child: Center(child: AppLottie.loading())),
            error:
                (e, _) => Expanded(
                  child: Center(
                    child: Text(
                      '${"Failed to load columns:".tr} $e',
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                ),
            data: (board) {
              final columns =
                  board?.projectProgresses ?? const <ProjectProgresses>[];
              return Expanded(
                child: ListView.builder(
                  addAutomaticKeepAlives: false,
                  cacheExtent: 300.0,
                  itemCount: columns.length,
                  itemBuilder: (_, i) {
                    final progress = columns[i];
                    final isSelected = pickedProgressId == progress.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: InkWell(
                        onTap:
                            () =>
                                ref
                                    .read(targetProgressIdProvider.notifier)
                                    .state = progress.id!,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? theme.themeColor.withValues(alpha: 0.1)
                                    : theme.textFieldColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  progress.name ?? 'Unnamed'.tr,
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
