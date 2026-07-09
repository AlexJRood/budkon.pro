// tms_app/todo/view/crm_tms_board.dart

import 'dart:async' show unawaited;

import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/common/drad_scroll_widget.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'package:tms_app/todo/models/board_details_model.dart';
import 'package:tms_app/todo/models/tasks_model.dart';
import 'package:tms_app/todo/provider/filtered_tasks_provider.dart';
import 'package:tms_app/todo/provider/task_filters_provider.dart';

import '../board/provider/board_details_provider.dart';
import '../board/provider/board_provider.dart';
import '../board/provider/tms_live_provider.dart';
import '../provider/task_management_provider.dart';
import '../provider/todo_provider.dart';
import 'drubale_column.dart';

class CrmToDoBoard extends ConsumerStatefulWidget {
  final bool isMobile;
  final bool readOnly;
  final BoardDetailsModel? boardDetailsOverride;

  const CrmToDoBoard({
    super.key,
    this.isMobile = false,
    this.readOnly = false,
    this.boardDetailsOverride,
  });

  @override
  ConsumerState<CrmToDoBoard> createState() => _CrmToDoBoardState();
}

class _CrmToDoBoardState extends ConsumerState<CrmToDoBoard> {
  final TextEditingController storyNameController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final GlobalKey _addListPopupKey = GlobalKey();
  final GlobalKey _addListInputKey = GlobalKey();

  late final FocusNode _addListFocusNode;
  ProviderSubscription<dynamic>? _boardIdSub;

  String? _lastFetchedBoardId;

  @override
  void initState() {
    super.initState();

    _addListFocusNode = FocusNode();
    _addListFocusNode.addListener(() {
      if (_addListFocusNode.hasFocus) {
        _centerAddListPopupHorizontally();
      }
    });

    _boardIdSub = ref.listenManual<dynamic>(
      boardIdProvider,
          (prev, next) async {
        final id = int.tryParse(next.toString()) ?? 0;
        if (id <= 0) return;

          if (_lastFetchedBoardId == id.toString()) return;
          _lastFetchedBoardId = id.toString();

        final loadingNotifier = ref.read(boardDetailsLoadingProvider.notifier);
        final detailsNotifier = ref.read(boardDetailsManagementProvider.notifier);

        loadingNotifier.state = true;

        try {
          await detailsNotifier.fetchBoardDetails(id.toString());
        } finally {
          loadingNotifier.state = false;
        }
      },
    );
  }

  @override
  void dispose() {
    _boardIdSub?.close();
    storyNameController.dispose();
    scrollController.dispose();
    _addListFocusNode.dispose();
    super.dispose();
  }

  Future<void> _centerAddListPopupHorizontally() async {
    if (!mounted) return;

    for (int i = 0; i < 16; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      if (MediaQuery.of(context).viewInsets.bottom > 0) {
        break;
      }
    }

    if (!mounted || !scrollController.hasClients) return;

    final ctx =
        _addListPopupKey.currentContext ?? _addListInputKey.currentContext;
    if (ctx == null) return;

    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox) return;

    final popupTopLeft = renderObject.localToGlobal(Offset.zero);
    final popupWidth = renderObject.size.width;
    final screenWidth = MediaQuery.of(context).size.width;

    final popupCenterX = popupTopLeft.dx + (popupWidth / 2);
    final screenCenterX = screenWidth / 2;
    final deltaToCenter = popupCenterX - screenCenterX;

    final target = (scrollController.offset + deltaToCenter).clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );

    if ((target - scrollController.offset).abs() > 1) {
      await scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _openAddListPopup() {
    if (widget.readOnly) return;
    ref.read(showAddListProvider.notifier).state = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      _addListFocusNode.requestFocus();

      await Future.delayed(const Duration(milliseconds: 10));
      if (!mounted) return;

      await _centerAddListPopupHorizontally();
    });
  }

  void _closeAddListPopup() {
    ref.read(showAddListProvider.notifier).state = false;
    ref.read(pendingTasksProvider.notifier).state = <int>{};
    storyNameController.clear();
    _addListFocusNode.unfocus();
  }

  Widget _withBoardRoot(Widget child) {
    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.tmsTodoBoardRoot
      anchorKey: 'tms.todo.board.root',
      runtimeMode: EmmaUiAnchorRuntimeMode.always,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: child,
    );
  }

  Widget _buildMobileDragHandle(dynamic theme) {
    return DragHandle(
      child: Padding(
        padding: const EdgeInsets.only(
          right: 20,
          top: 30,
          bottom: 30,
        ),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.drag_indicator,
            size: 18,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }

  DragAndDropList _buildAddListColumn({
    required bool showAddList,
    required dynamic theme,
    required TaskDataState boardState,
    required Set<int> pending,
  }) {
    if (showAddList) {
      return DragAndDropList(
        canDrag: false,
        children: [
          DragAndDropItem(
            canDrag: false,
            child: EmmaUiAnchorTarget(
              // @emma-backend: EmmaAnchors.tmsTodoBoardAddListForm
              anchorKey: 'tms.todo.board.add_list_form',
              tapMode: EmmaUiAnchorTapMode.disabled,
              child: Container(
                key: _addListPopupKey,
                padding: const EdgeInsets.all(10),
                width: widget.isMobile ? 280 : 300,
                decoration: BoxDecoration(
                  color: theme.adPopBackground.withAlpha(
                    (255 * 0.5).toInt(),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    EmmaUiAnchorTarget(
                      // @emma-backend: EmmaAnchors.tmsTodoBoardAddListInput
                      anchorKey: 'tms.todo.board.add_list_input',
                      child: TextField(
                        key: _addListInputKey,
                        focusNode: _addListFocusNode,
                        style: TextStyle(color: theme.textColor),
                        autofocus: false,
                        controller: storyNameController,
                        cursorColor: theme.textColor,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.textFieldColor,
                          hintText: 'Enter List Name'.tr,
                          hintStyle: AppTextStyles.interMedium.copyWith(
                            color: theme.textColor,
                          ),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _addListAndMoveAllPending(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (pending.isNotEmpty) ...[
                      EmmaUiAnchorTarget(
                        // @emma-backend: EmmaAnchors.tmsTodoBoardPendingTasksInfo
                        anchorKey: 'tms.todo.board.pending_tasks_info',
                        tapMode: EmmaUiAnchorTapMode.disabled,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.textFieldColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: theme.textColor.withValues(alpha: .1),
                            ),
                          ),
                          child: Text(
                            '${'Tasks queued'.tr}: ${pending.length}\n${'They will be moved to this new list'.tr}.',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.textFieldColor,
                            foregroundColor: theme.textFieldColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                          ),
                          onPressed: _addListAndMoveAllPending,
                          child: boardState == TaskState.loading
                              ? Center(child: AppLottie.loading())
                              : Text(
                                  'Add to List'.tr,
                                  style: TextStyle(
                                    color: theme.textColor,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: AppIcons.close(color: theme.textColor),
                          onPressed: _closeAddListPopup,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return DragAndDropList(
      canDrag: false,
      children: [
        DragAndDropItem(
          canDrag: false,
          child: EmmaUiAnchorTarget(
            // @emma-backend: EmmaAnchors.tmsTodoBoardAddListButton
            anchorKey: 'tms.todo.board.add_list_button',
            child: InkWell(
              onTap: _openAddListPopup,
              child: Container(
                width: widget.isMobile ? 280 : 300,
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: theme.adPopBackground.withAlpha(
                    (255 * 0.6).toInt(),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 5,
                  children: [
                    Icon(Icons.add, color: theme.textColor),
                    Expanded(
                      child: Text(
                        'ADD ANOTHER LIST'.tr,
                        style: TextStyle(color: theme.textColor),
                      ),
                    ),
                    if (pending.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.textFieldColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${pending.length}',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleItemReorder(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
  ) {
    if (widget.readOnly) return;
    final boardDetails = ref.read(boardDetailsStateProvider);
    final progresses = List.of(
      boardDetails.projectProgresses ?? const [],
    );

    final addListIndex = progresses.length;

    if (newListIndex == addListIndex) {
      if (oldListIndex < 0 || oldListIndex >= progresses.length) return;

      final oldTasks = progresses[oldListIndex].tasks ?? <Tasks>[];
      if (oldItemIndex < 0 || oldItemIndex >= oldTasks.length) return;

      final taskId = oldTasks[oldItemIndex].id;
      if (taskId != null) {
        final next = {...ref.read(pendingTasksProvider)};
        next.add(taskId);

        ref.read(pendingTasksProvider.notifier).state = next;
        ref.read(showAddListProvider.notifier).state = true;

        if (mounted) setState(() {});
      }

      return;
    }

    if (oldListIndex < 0 || oldListIndex >= progresses.length) return;
    if (newListIndex < 0 || newListIndex >= progresses.length) return;

    final oldList = progresses[oldListIndex];
    final newList = progresses[newListIndex];

    final oldTasks = oldList.tasks ?? <Tasks>[];
    final newTasks = newList.tasks ?? <Tasks>[];

    if (oldItemIndex < 0 || oldItemIndex >= oldTasks.length) return;

    if (oldListIndex == newListIndex) {
      final moved = oldTasks.removeAt(oldItemIndex);
      final insertIndex = newItemIndex.clamp(0, oldTasks.length).toInt();

      oldTasks.insert(insertIndex, moved);

      if (mounted) setState(() {});

      final orderedIds = oldTasks.map((t) => t.id).whereType<int>().toList();
      final progressId = oldList.id;
      final projectId = moved.projectId;

      if (progressId != null && projectId != null) {
        unawaited(
          ref.read(taskProvider.notifier).reOrderTask(
                projectId: projectId,
                progressId: progressId,
                orderedTaskIds: orderedIds,
              ),
        );
      }

      return;
    }

    final taken = oldTasks.removeAt(oldItemIndex);

    final updatedTaken = taken.copyWith(
      progressId: newList.id ?? taken.progressId,
    );

    final insertIndex = newItemIndex.clamp(0, newTasks.length).toInt();
    newTasks.insert(insertIndex, updatedTaken);

    if (mounted) setState(() {});

    if (taken.id != null && newList.id != null) {
      unawaited(
        ref.read(taskProvider.notifier).reProgressTask(
              taken.id!,
              newList.id!,
            ),
      );
    }

    final projectId = updatedTaken.projectId ?? taken.projectId;
    if (projectId == null) return;

    final oldOrderedIds = oldTasks.map((t) => t.id).whereType<int>().toList();
    final newOrderedIds = newTasks.map((t) => t.id).whereType<int>().toList();

    if (oldList.id != null) {
      unawaited(
        ref.read(taskProvider.notifier).reOrderTask(
              projectId: projectId,
              progressId: oldList.id!,
              orderedTaskIds: oldOrderedIds,
            ),
      );
    }

    if (newList.id != null) {
      unawaited(
        ref.read(taskProvider.notifier).reOrderTask(
              projectId: projectId,
              progressId: newList.id!,
              orderedTaskIds: newOrderedIds,
            ),
      );
    }
  }

  void _handleListReorder(int oldListIndex, int newListIndex) {
    if (widget.readOnly) return;
    final boardDetails = ref.read(boardDetailsManagementProvider).boardDetails;
    final progresses = boardDetails.projectProgresses ?? const [];

    if (progresses.isEmpty) return;
    if (oldListIndex < 0 || oldListIndex >= progresses.length) return;

    final moved = progresses.removeAt(oldListIndex);
    final insertAt = newListIndex.clamp(0, progresses.length).toInt();

    progresses.insert(insertAt, moved);

    if (mounted) setState(() {});

    ref
        .read(taskManagementProvider.notifier)
        .onListReorder(oldListIndex, insertAt, progresses, ref);

    final columnId = moved.id?.toString();
    if (columnId == null) return;

    ref.read(taskManagementProvider.notifier).columnReorder(
          ref.read(boardIdProvider).toString(),
          columnId,
          insertAt,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Wpięcie w szynę live (real-time invalidacje tablicy) — aktywne tylko dla
    // realnej, edytowalnej tablicy. Subskrybuje `board:<id>` i na sygnał odpala
    // delta-sync przez fetchBoardDetails.
    if (!widget.readOnly && widget.boardDetailsOverride == null) {
      ref.watch(tmsLiveProvider);
    }

    final showAddList = widget.readOnly
        ? false
        : ref.watch(showAddListProvider);
    final storiesList = widget.boardDetailsOverride ??
        ref.watch(boardDetailsManagementProvider).boardDetails;
    final boardState = widget.readOnly
        ? const TaskDataState()
        : ref.watch(taskProvider);
    final theme = ref.read(themeColorsProvider);
    final pending = widget.readOnly
        ? const <int>{}
        : ref.watch(pendingTasksProvider);
    final isBoardDetailsLoading = ref.watch(boardDetailsLoadingProvider);

    if (isBoardDetailsLoading) {
      return _withBoardRoot(
        Center(child: AppLottie.loading(size: 450)),
      );
    }

    if (storiesList.name?.isEmpty ?? true) {
      return _withBoardRoot(
        Center(
          child: AppLottie.noResults(size: 450),
        ),
      );
    }
    final progresses = storiesList.projectProgresses ?? [];
    final qp = widget.readOnly
        ? const <String, dynamic>{}
        : ref.watch(appliedTaskFiltersProvider).toQueryParams(ref);
    final hasFilters = !widget.readOnly && qp.isNotEmpty;

    final filteredTasks = widget.readOnly
        ? const <Tasks>[]
        : ref.watch(filteredTasksProvider).maybeWhen(
              data: (tasks) => tasks,
              orElse: () => <Tasks>[],
            );

    return _withBoardRoot(
      EmmaUiAnchorTarget(
        // @emma-backend: EmmaAnchors.tmsTodoBoardDragSurface
        anchorKey: 'tms.todo.board.drag_surface',
        tapMode: EmmaUiAnchorTapMode.disabled,
        child: DragScrollView(
          controller: scrollController,
          child: DragAndDropLists(
            itemDragOnLongPress: !widget.readOnly && widget.isMobile,
            listDragOnLongPress: !widget.readOnly && widget.isMobile,
            itemDragHandle: !widget.readOnly && widget.isMobile
            ? DragHandle(
          child: Padding(
            padding: const EdgeInsets.only(right: 20, top: 30, bottom: 30),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.drag_indicator,
                size: 18,
                color: theme.textColor,
              ),
            ),
          ),
        )
            : null,
            listDivider: Container(
              width: 1,
              color: theme.adPopBackground,
            ),
            scrollController: scrollController,
            children: List.generate(
              progresses.length + (widget.readOnly ? 0 : 1),
              (index) {
              final isAddListColumn =
                  !widget.readOnly && index == progresses.length;

              if (isAddListColumn) {
                return _buildAddListColumn(
                  showAddList: showAddList,
                  theme: theme,
                  boardState: boardState,
                  pending: pending,
                );
              }

              final originalProgress = progresses[index];

              final tasksForThisProgress = hasFilters
                  ? filteredTasks
                      .where((t) => t.progressId == originalProgress.id)
                      .toList()
                  : (originalProgress.tasks ?? <Tasks>[]);

              final progressForUi = originalProgress.copyWith(
                tasks: tasksForThisProgress,
              );

              return DraggableWidget().draggableWidget(
                isMobile: widget.isMobile,
                story: progressForUi,
                storyIndex: index,
                context: context,
                projectId: (storiesList.id ?? ref.read(boardIdProvider) ?? 0).toString(),
                ref: ref,
                horizontalScrollController: scrollController,
                readOnly: widget.readOnly,
              );
            }),
            onItemReorder: widget.readOnly
                ? (_, __, ___, ____) {}
                : _handleItemReorder,
            onItemAdd: (newItem, listIndex, newItemIndex) {
              if (kDebugMode) {
                debugPrint(
                  'younis new Item: $newItem  listIndex: $listIndex newItemIndex: $newItemIndex',
                );
              }
            },
            onListReorder: widget.readOnly
                ? (_, __) {}
                : _handleListReorder,
            axis: Axis.horizontal,
            listWidth: widget.isMobile ? 280 : 300,
            listDraggingWidth: widget.isMobile ? 280 : 300,
            listPadding: const EdgeInsets.all(10),
          ),
        ),
      ),
    );
  }

  Future<void> _addListAndMoveAllPending() async {
    if (widget.readOnly) return;
    final boardId = ref.read(boardIdProvider).toString();
    final name = storyNameController.text.trim();

    storyNameController.clear();
    ref.read(showAddListProvider.notifier).state = false;

    if (name.isEmpty) return;

    ref.read(taskManagementProvider.notifier).addStory(name);

    try {
      final int newProgressId =
          await ref.read(taskProvider.notifier).addProgressBar(
                boardId,
                name,
              );

      final taskIds = ref.read(pendingTasksProvider).toList();
      ref.read(pendingTasksProvider.notifier).state = <int>{};

      if (taskIds.isNotEmpty) {
        await Future.wait(
          taskIds.map(
            (taskId) => ref
                .read(taskProvider.notifier)
                .reProgressTask(taskId, newProgressId),
          ),
        );
      }

      unawaited(
        ref
            .read(boardDetailsManagementProvider.notifier)
            .fetchBoardDetails(boardId),
      );
    } catch (_) {
      unawaited(
        ref
            .read(boardDetailsManagementProvider.notifier)
            .fetchBoardDetails(boardId),
      );
    } finally {
      if (mounted) {
        ref.read(showAddListProvider.notifier).state = false;
      }

      storyNameController.clear();
      _addListFocusNode.unfocus();
    }
  }
}