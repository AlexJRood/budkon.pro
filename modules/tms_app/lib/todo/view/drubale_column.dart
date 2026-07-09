// tms_app/todo/view/drubale_column.dart

import 'dart:developer' as developer;

import 'package:automation/src/widgets/popup/automation_context_launcher.dart';
import 'package:drag_and_drop_lists/drag_and_drop_item.dart';
import 'package:drag_and_drop_lists/drag_and_drop_list.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'package:tms_app/todo/view/widgets/task_card_widget.dart';

import '../board/provider/board_details_provider.dart';
import '../board/provider/board_provider.dart';
import '../models/board_progress_model.dart';
import '../models/tasks_model.dart';
import '../provider/task_management_provider.dart';
import '../provider/todo_provider.dart';
import 'task_pup_up.dart';

class DraggableWidget {
  DragAndDropList draggableWidget({
    required BuildContext context,
    required ProjectProgresses story,
    required int storyIndex,
    bool isMobile = false,
    required String projectId,
    required WidgetRef ref,
    required ScrollController horizontalScrollController,
    bool readOnly = false,
  }) {
    final theme = ref.read(themeColorsProvider);

    return DragAndDropList(
      canDrag: !readOnly,
      contentsWhenEmpty: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Text(
          'No task in this story'.tr,
          style: AppTextStyles.interMedium.copyWith(
            color: theme.textColor,
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withAlpha((255 * 0.25).toInt()),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      header: BuildHeader(
        story.name ?? '',
        isMobile: isMobile,
        progressId: story.id?.toString() ?? '',
        projectId: story.project.toString(),
        storyIndex: storyIndex,
        readOnly: readOnly,
      ),
      footer: readOnly
          ? null
          : BuildFooter(
              storyIndex,
              projectId: projectId,
              isMobile: isMobile,
              horizontalScrollController: horizontalScrollController,
            ),
      children: List.generate(
        story.tasks?.length ?? 0,
        growable: false,
        (index) {
          return DraggableItemWidget().buildItem(
            context,
            story.tasks![index],
            ref,
            storyIndex: storyIndex,
            taskIndex: index,
            readOnly: readOnly,
          );
        },
      ),
    );
  }
}

final editingColumnIdProvider = StateProvider<String?>((ref) => null);

class BuildHeader extends ConsumerStatefulWidget {
  const BuildHeader(
    this.title, {
    super.key,
    required this.progressId,
    required this.projectId,
    required this.storyIndex,
    this.isMobile = false,
    this.readOnly = false,
  });

  final String title;
  final String projectId;
  final String progressId;
  final int storyIndex;
  final bool isMobile;
  final bool readOnly;

  @override
  ConsumerState<BuildHeader> createState() => _BuildHeaderState();
}

class _BuildHeaderState extends ConsumerState<BuildHeader> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  bool get _isFirstColumn => widget.storyIndex == 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant BuildHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isEditing = ref.read(editingColumnIdProvider) == widget.progressId;

    if (!isEditing && oldWidget.title != widget.title) {
      _controller.text = widget.title;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _enterInlineEdit() {
    if (widget.readOnly) return;
    ref.read(editingColumnIdProvider.notifier).state = widget.progressId;

    _controller.value = TextEditingValue(
      text: widget.title,
      selection: TextSelection.collapsed(offset: widget.title.length),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _focusNode.requestFocus();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  void _cancelInlineEdit() {
    _focusNode.unfocus();
    ref.read(editingColumnIdProvider.notifier).state = null;
    _controller.text = widget.title;
  }

  Future<void> _submitInlineEdit() async {
    if (widget.readOnly) return;
    final name = _controller.text.trim();

    if (name.isEmpty || name == widget.title.trim()) {
      _cancelInlineEdit();
      return;
    }

    await ref.read(taskProvider.notifier).updateProgressBar(
          projectId: widget.projectId,
          progressId: widget.progressId,
          name: name,
        );

    await ref
        .read(boardDetailsManagementProvider.notifier)
        .fetchBoardDetails(ref.read(boardIdProvider).toString());

    if (!mounted) return;

    _cancelInlineEdit();
  }

  Widget _buildInlineEditField(dynamic theme) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _submitInlineEdit();
              return null;
            },
          ),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _cancelInlineEdit();
              return null;
            },
          ),
        },
        child: TapRegion(
          onTapOutside: (_) => _cancelInlineEdit(),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey('edit_${widget.progressId}'),
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitInlineEdit(),
                  style: AppTextStyles.interMedium14.copyWith(
                    color: theme.textColor,
                  ),
                  cursorColor: theme.textColor,
                  cursorWidth: 2,
                  showCursor: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    filled: true,
                    fillColor: theme.textFieldColor,
                    hintText: 'Enter List Name'.tr,
                    hintStyle: AppTextStyles.interMedium14.copyWith(
                      color: theme.textColor,
                    ),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.check),
                color: theme.textColor,
                tooltip: 'Save'.tr,
                onPressed: _submitInlineEdit,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                color: theme.textColor,
                tooltip: 'Cancel'.tr,
                onPressed: _cancelInlineEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTitle(dynamic theme) {
    final title = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        widget.title,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.interMedium14.copyWith(
          color: theme.textColor,
        ),
      ),
    );

    if (widget.readOnly) return title;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _enterInlineEdit,
      child: title,
    );
  }

  Widget _buildMenuButton(dynamic theme) {
    final menuButton = GestureDetector(
      onTapDown: (details) => _showPopover(context, details, theme),
      child: AppIcons.moreVertical(color: theme.textColor),
    );

    if (!_isFirstColumn) {
      return menuButton;
    }

    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.tmsTodoBoardFirstColumnMenuButton
      anchorKey: 'tms.todo.board.first_column.menu_button',
      child: menuButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeColorsProvider);
    final editingId = ref.watch(editingColumnIdProvider);
    final isEditing = !widget.readOnly && editingId == widget.progressId;

    final header = Container(
      width: widget.isMobile ? 280 : 300,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: isEditing
                ? _buildInlineEditField(theme)
                : _buildHeaderTitle(theme),
          ),
          if (!isEditing && !widget.readOnly) _buildMenuButton(theme),
        ],
      ),
    );

    if (!_isFirstColumn) {
      return header;
    }

    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.tmsTodoBoardFirstColumnHeader
      anchorKey: 'tms.todo.board.first_column.header',
      child: header,
    );
  }

  void _showPopover(
    BuildContext context,
    TapDownDetails details,
    dynamic theme,
  ) {
    showMenu<int>(
      color: theme.textFieldColor,
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              AppIcons.add(color: theme.textColor),
              const SizedBox(width: 8),
              Text(
                'Add task'.tr,
                style: TextStyle(color: theme.textColor),
              ),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: Row(
            children: [
              AppIcons.pencil(color: theme.textColor),
              const SizedBox(width: 8),
              Text(
                'Edit progress'.tr,
                style: AppTextStyles.interMedium.copyWith(
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 4,
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_motion_rounded,
                color: theme.textColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Automation'.tr,
                style: AppTextStyles.interMedium.copyWith(
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 3,
          child: Row(
            children: [
              AppIcons.delete(color: AppColors.redBeige),
              const SizedBox(width: 8),
              Text(
                'Delete'.tr,
                style: AppTextStyles.interMedium.copyWith(
                  color: theme.textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (!mounted) return;

      if (value == 3) {
        _onDelete();
      } else if (value == 1) {
        _onAddTask();
      } else if (value == 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _enterInlineEdit();
        });
      } else if (value == 4) {
        openTmsColumnAutomationStudio(
          theme,
          context,
          columnId: widget.progressId,
          columnKey: 'tms.column.${widget.progressId}',
          columnName: widget.title,
          boardId: widget.projectId,
        );
      }
    });
  }

  void _onAddTask() {
    final current = ref.read(showAddTaskProvider);
    final safe = List<bool>.from(current);

    if (safe.length <= widget.storyIndex) {
      safe.addAll(
        List<bool>.filled(widget.storyIndex + 1 - safe.length, false),
      );
    }

    safe[widget.storyIndex] = true;
    ref.read(showAddTaskProvider.notifier).state = safe;
  }

  void _onDelete() {
    _showDeleteChoiceDialog();
  }

  Future<void> _showDeleteChoiceDialog() async {
    final theme = ref.read(themeColorsProvider);

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete column?'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Do you want to move incomplete tasks to another column before deleting, or delete now?'
                    .tr,
                style: TextStyle(color: theme.textColor),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();

                        await ref.read(taskProvider.notifier).deleteProgressBar(
                              widget.projectId,
                              widget.progressId,
                            );

                        await ref
                            .read(boardDetailsManagementProvider.notifier)
                            .fetchBoardDetails(
                              ref.read(boardIdProvider).toString(),
                            );
                      },
                      child: Text(
                        'Delete'.tr,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _showMoveIncompleteTasksDialog();
                      },
                      child: Text(
                        'Move'.tr,
                        style: TextStyle(color: theme.themeTextColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMoveIncompleteTasksDialog() async {
    final theme = ref.read(themeColorsProvider);
    final board = ref.read(boardDetailsStateProvider);
    final progresses = board.projectProgresses ?? <ProjectProgresses>[];

    final currentProgress = progresses.firstWhere(
      (p) => p.id?.toString() == widget.progressId,
      orElse: () => ProjectProgresses(tasks: const []),
    );

    final incomplete = (currentProgress.tasks ?? const <Tasks>[])
        .where((t) => !(t.isCompleted ?? false))
        .toList();

    if (incomplete.isEmpty) {
      await ref.read(taskProvider.notifier).deleteProgressBar(
            widget.projectId,
            widget.progressId,
          );

      await ref
          .read(boardDetailsManagementProvider.notifier)
          .fetchBoardDetails(ref.read(boardIdProvider).toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No incomplete tasks. Column deleted.'.tr),
          ),
        );
      }

      return;
    }

    final destinations =
        progresses.where((p) => p.id != currentProgress.id).toList();

    int? selectedDestId = destinations.isNotEmpty ? destinations.first.id : null;
    final selectedTaskIds = incomplete.map((t) => t.id!).toSet();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.adPopBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Move incomplete tasks'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Destination column'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: selectedDestId,
                    dropdownColor: theme.adPopBackground,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.textFieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    items: destinations.map((p) {
                      return DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(
                          p.name ?? 'Column ${p.id}',
                          style: TextStyle(color: theme.textColor),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => selectedDestId = v),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select tasks to move'.tr,
                      style: TextStyle(color: theme.textColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      addAutomaticKeepAlives: false,
                      cacheExtent: 300.0,
                      shrinkWrap: true,
                      itemCount: incomplete.length,
                      itemBuilder: (_, i) {
                        final task = incomplete[i];
                        final checked = selectedTaskIds.contains(task.id);

                        return CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: theme.themeColor,
                          value: checked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedTaskIds.add(task.id!);
                              } else {
                                selectedTaskIds.remove(task.id);
                              }
                            });
                          },
                          title: Text(
                            task.name ?? 'Task ${task.id}',
                            style: TextStyle(color: theme.textColor),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'Cancel'.tr,
                            style: AppTextStyles.interMedium.copyWith(
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: selectedDestId == null ||
                                  selectedTaskIds.isEmpty
                              ? null
                              : () async {
                                  for (final id in selectedTaskIds) {
                                    await ref
                                        .read(taskProvider.notifier)
                                        .reProgressTask(
                                          id,
                                          selectedDestId!,
                                        );
                                  }

                                  await ref
                                      .read(taskProvider.notifier)
                                      .deleteProgressBar(
                                        widget.projectId,
                                        widget.progressId,
                                      );

                                  await ref
                                      .read(
                                        boardDetailsManagementProvider.notifier,
                                      )
                                      .fetchBoardDetails(
                                        ref
                                            .read(boardIdProvider)
                                            .toString(),
                                      );

                                  if (context.mounted) {
                                    Navigator.of(ctx).pop();
                                  }
                                },
                          child: Text(
                            'Move & Delete'.tr,
                            style: TextStyle(color: theme.themeTextColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BuildFooter extends ConsumerStatefulWidget {
  final int storyIndex;
  final String projectId;
  final bool isMobile;
  final ScrollController horizontalScrollController;

  const BuildFooter(
    this.storyIndex, {
    super.key,
    required this.projectId,
    this.isMobile = false,
    required this.horizontalScrollController,
  });

  @override
  ConsumerState<BuildFooter> createState() => _BuildFooterState();
}

class _BuildFooterState extends ConsumerState<BuildFooter> {
  final GlobalKey _addCardKey = GlobalKey();
  final GlobalKey _inputKey = GlobalKey();

  late final TextEditingController _taskNameController;
  late final FocusNode _taskFocusNode;

  bool get _isFirstColumn => widget.storyIndex == 0;

  @override
  void initState() {
    super.initState();

    _taskNameController = TextEditingController();
    _taskFocusNode = FocusNode();

    _taskFocusNode.addListener(() {
      if (_taskFocusNode.hasFocus) {
        _scrollFieldAboveKeyboard();
      }
    });
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskFocusNode.dispose();
    super.dispose();
  }

  bool _isAddTaskOpen(List<bool> showAddTask) {
    if (widget.storyIndex < 0) return false;
    if (widget.storyIndex >= showAddTask.length) return false;

    return showAddTask[widget.storyIndex];
  }

  Future<void> _centerFieldHorizontally() async {
    if (!mounted) return;

    final ctx = _inputKey.currentContext ?? _addCardKey.currentContext;
    if (ctx == null) return;

    final horizontalController = widget.horizontalScrollController;
    if (!horizontalController.hasClients) return;

    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox) return;

    final fieldTopLeft = renderObject.localToGlobal(Offset.zero);
    final fieldWidth = renderObject.size.width;
    final screenWidth = MediaQuery.of(context).size.width;

    final fieldCenterX = fieldTopLeft.dx + (fieldWidth / 2);
    final screenCenterX = screenWidth / 2;
    final deltaToCenter = fieldCenterX - screenCenterX;

    final target = (horizontalController.offset + deltaToCenter).clamp(
      horizontalController.position.minScrollExtent,
      horizontalController.position.maxScrollExtent,
    );

    if ((target - horizontalController.offset).abs() > 1) {
      await horizontalController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _scrollFieldAboveKeyboard() async {
    if (!mounted) return;

    for (int i = 0; i < 16; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      if (MediaQuery.of(context).viewInsets.bottom > 0) {
        break;
      }
    }

    if (!mounted) return;

    final ctx = _inputKey.currentContext ?? _addCardKey.currentContext;
    if (ctx == null) return;

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.0,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    await _centerFieldHorizontally();
  }

  void _openAddCard() {
    _setPopupState(true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      _taskFocusNode.requestFocus();

      await Future.delayed(const Duration(milliseconds: 10));

      if (!mounted) return;

      await _scrollFieldAboveKeyboard();
    });
  }

  void _closeAddCard() {
    _setPopupState(false);
    _taskNameController.clear();
    _taskFocusNode.unfocus();
  }

  Future<void> _handleAddTask() async {
    final text = _taskNameController.text.trim();
    if (text.isEmpty) return;

    try {
      ref.read(taskManagementProvider.notifier).addTaskToStory(
            widget.storyIndex,
            text,
          );

      await ref.read(taskProvider.notifier).addTask(
            text,
            widget.storyIndex,
            widget.projectId,
          );

      await ref
          .read(boardDetailsManagementProvider.notifier)
          .fetchBoardDetails(ref.read(boardIdProvider).toString());

      _setPopupState(true);
      _taskNameController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        _taskFocusNode.requestFocus();
        await _scrollFieldAboveKeyboard();
      });
    } catch (e, st) {
      developer.log('Error adding task: $e', stackTrace: st);
    }
  }

  void _setPopupState(bool isOpen) {
    final current = ref.read(showAddTaskProvider);
    final safe = List<bool>.from(current);

    if (safe.length <= widget.storyIndex) {
      safe.addAll(
        List<bool>.filled(widget.storyIndex + 1 - safe.length, false),
      );
    }

    safe[widget.storyIndex] = isOpen;
    ref.read(showAddTaskProvider.notifier).state = safe;
  }

  Widget _buildAddCardButton(dynamic theme) {
    return ElevatedButton(
      style: elevatedButtonStyleRounded6.copyWith(
        backgroundColor: WidgetStateProperty.all(
          theme.textFieldColor.withAlpha((255 * 0.15).toInt()),
        ),
      ),
      onPressed: _openAddCard,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: theme.textColor, size: 15),
            Text(
              'Add a card'.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnchoredAddCardButton(dynamic theme) {
    final button = _buildAddCardButton(theme);

    if (!_isFirstColumn) {
      return button;
    }

    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.tmsTodoBoardFirstColumnAddCardButton
      anchorKey: 'tms.todo.board.first_column.add_card_button',
      child: button,
    );
  }

  Widget _buildTaskNameInput(dynamic theme) {
    final input = TextField(
      key: _inputKey,
      focusNode: _taskFocusNode,
      maxLength: 50,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      inputFormatters: [
        LengthLimitingTextInputFormatter(50),
      ],
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      minLines: 1,
      maxLines: 3,
      style: TextStyle(color: theme.textColor),
      autofocus: false,
      controller: _taskNameController,
      cursorColor: theme.textColor,
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.textFieldColor,
        hintText: 'Enter Task Name'.tr,
        hintStyle: AppTextStyles.interMedium14.copyWith(
          color: theme.textColor,
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide.none,
        ),
      ),
      buildCounter: (
        context, {
        required int currentLength,
        required bool isFocused,
        required int? maxLength,
      }) {
        return Text(
          '$currentLength / $maxLength',
          style: TextStyle(
            fontSize: 11,
            color: currentLength >= maxLength!
                ? Colors.redAccent
                : theme.textColor.withOpacity(0.6),
          ),
        );
      },
    );

    if (!_isFirstColumn) {
      return input;
    }

    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.tmsTodoBoardFirstColumnAddCardInput
      anchorKey: 'tms.todo.board.first_column.add_card_input',
      child: input,
    );
  }

  Widget _buildAddCardForm(dynamic theme, TaskDataState addTaskState) {
    final form = Container(
      key: _addCardKey,
      padding: const EdgeInsets.all(10),
      width: widget.isMobile ? 280 : 300,
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha((255 * 0.5).toInt()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          const SizedBox(height: 5),
          Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

                if (!isShiftPressed) {
                  _handleAddTask();
                  return KeyEventResult.handled;
                }
              }

              return KeyEventResult.ignored;
            },
            child: _buildTaskNameInput(theme),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.textFieldColor,
                  foregroundColor: theme.textFieldColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                ),
                onPressed: _handleAddTask,
                child: addTaskState == TaskState.loading
                    ? Center(child: AppLottie.loading())
                    : Text(
                        'Add Task'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
              ),
              const Spacer(),
              IconButton(
                style: elevatedButtonStyleRounded10,
                icon: AppIcons.close(color: theme.textColor),
                onPressed: _closeAddCard,
              ),
            ],
          ),
        ],
      ),
    );

    if (!_isFirstColumn) {
      return form;
    }

    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.tmsTodoBoardFirstColumnAddCardForm
      anchorKey: 'tms.todo.board.first_column.add_card_form',
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: form,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAddTask = ref.watch(showAddTaskProvider);
    final addTaskState = ref.watch(taskProvider);
    final theme = ref.read(themeColorsProvider);

    final isAddTaskOpen = _isAddTaskOpen(showAddTask);

    return Center(
      child: Column(
        children: [
          if (!isAddTaskOpen) _buildAnchoredAddCardButton(theme),
          if (isAddTaskOpen) _buildAddCardForm(theme, addTaskState),
        ],
      ),
    );
  }
}

class DraggableItemWidget {
  DragAndDropItem buildItem(
    BuildContext context,
    Tasks task,
    WidgetRef ref, {
    int storyIndex = 0,
    int taskIndex = 0,
    bool readOnly = false,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 650;

    final card = GestureDetector(
      onTap: () async {
        if (isMobile) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.4,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) => TaskDetailsPopup(
                  task: task,
                  isMobile: true,
                  scrollController: scrollController,
                  readOnly: readOnly,
                ),
              );
            },
          );
        } else {
          await showDialog(
            context: context,
            builder: (_) => TaskDetailsPopup(
              task: task,
              isMobile: false,
              readOnly: readOnly,
            ),
          );
        }

        if (!readOnly) {
          await ref
              .read(boardDetailsManagementProvider.notifier)
              .fetchBoardDetails(ref.read(boardIdProvider).toString());
        }
      },
      child: TaskCardWidget(
        task: task,
        readOnly: readOnly,
      ),
    );

    return DragAndDropItem(
      canDrag: !readOnly,
      child: storyIndex == 0 && taskIndex == 0
          ? EmmaUiAnchorTarget(
              // @emma-backend: EmmaAnchors.tmsTodoBoardFirstTaskCard
              anchorKey: 'tms.todo.board.first_task_card',
              child: card,
            )
          : card,
    );
  }
}