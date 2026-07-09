import 'dart:async';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:crm/widget/create_todo_board_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:tms_app/todo/board/provider/board_details_provider.dart';
import 'package:tms_app/todo/board/provider/board_provider.dart';
import 'package:tms_app/todo/local/tms_local_store.dart';
import 'package:tms_app/todo/local/tms_sync_service.dart';
import 'package:tms_app/todo/models/board_details_model.dart';
import 'package:tms_app/todo/models/board_progress_model.dart';
import 'package:tms_app/todo/models/get_user_board_model.dart';
import 'package:tms_app/todo/models/tasks_model.dart';
import 'package:tms_app/todo/provider/task_management_provider.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:tms_app/todo/view/task_pup_up.dart';
import 'package:tms_app/todo/view/widgets/tms_sync_status_chip.dart';
import 'package:core/user/user/user_provider.dart';

enum DashboardTmsFilter {
  latest,
  mine,
  open,
  overdue,
  dueSoon,
  completed,
}

extension DashboardTmsFilterX on DashboardTmsFilter {
  String get key {
    switch (this) {
      case DashboardTmsFilter.latest:
        return 'latest';
      case DashboardTmsFilter.mine:
        return 'mine';
      case DashboardTmsFilter.open:
        return 'open';
      case DashboardTmsFilter.overdue:
        return 'overdue';
      case DashboardTmsFilter.dueSoon:
        return 'due_soon';
      case DashboardTmsFilter.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case DashboardTmsFilter.latest:
        return 'Latest';
      case DashboardTmsFilter.mine:
        return 'Mine';
      case DashboardTmsFilter.open:
        return 'Open';
      case DashboardTmsFilter.overdue:
        return 'Overdue';
      case DashboardTmsFilter.dueSoon:
        return 'Due soon';
      case DashboardTmsFilter.completed:
        return 'Completed';
    }
  }

  IconData get icon {
    switch (this) {
      case DashboardTmsFilter.latest:
        return Icons.schedule_rounded;
      case DashboardTmsFilter.mine:
        return Icons.person_outline_rounded;
      case DashboardTmsFilter.open:
        return Icons.radio_button_unchecked_rounded;
      case DashboardTmsFilter.overdue:
        return Icons.warning_amber_rounded;
      case DashboardTmsFilter.dueSoon:
        return Icons.event_available_rounded;
      case DashboardTmsFilter.completed:
        return Icons.check_circle_outline_rounded;
    }
  }

  static DashboardTmsFilter fromRaw(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'mine':
      case 'my':
      case 'my_tasks':
        return DashboardTmsFilter.mine;
      case 'open':
      case 'active':
        return DashboardTmsFilter.open;
      case 'overdue':
        return DashboardTmsFilter.overdue;
      case 'due_soon':
      case 'soon':
        return DashboardTmsFilter.dueSoon;
      case 'completed':
      case 'done':
        return DashboardTmsFilter.completed;
      case 'latest':
      default:
        return DashboardTmsFilter.latest;
    }
  }
}

enum DashboardTmsLayout {
  auto,
  vertical,
  horizontal,
}

extension DashboardTmsLayoutX on DashboardTmsLayout {
  String get key {
    switch (this) {
      case DashboardTmsLayout.auto:
        return 'auto';
      case DashboardTmsLayout.vertical:
        return 'vertical';
      case DashboardTmsLayout.horizontal:
        return 'horizontal';
    }
  }

  String get label {
    switch (this) {
      case DashboardTmsLayout.auto:
        return 'Auto';
      case DashboardTmsLayout.vertical:
        return 'Vertical';
      case DashboardTmsLayout.horizontal:
        return 'Horizontal';
    }
  }

  IconData get icon {
    switch (this) {
      case DashboardTmsLayout.auto:
        return Icons.auto_awesome_motion_outlined;
      case DashboardTmsLayout.vertical:
        return Icons.view_agenda_outlined;
      case DashboardTmsLayout.horizontal:
        return Icons.view_column_outlined;
    }
  }

  static DashboardTmsLayout fromRaw(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'vertical':
        return DashboardTmsLayout.vertical;
      case 'horizontal':
        return DashboardTmsLayout.horizontal;
      case 'auto':
      default:
        return DashboardTmsLayout.auto;
    }
  }
}

class DashboardTmsWidget extends ConsumerStatefulWidget {
  final bool isMobile;
  final AppModule appModule;
  final Map<String, dynamic> settings;

  const DashboardTmsWidget({
    super.key,
    required this.isMobile,
    this.appModule = AppModule.agentCrm,
    this.settings = const {},
  });

  @override
  ConsumerState<DashboardTmsWidget> createState() => _DashboardTmsWidgetState();
}

class _DashboardTmsWidgetState extends ConsumerState<DashboardTmsWidget> {
  DashboardTmsFilter? _runtimeFilter;
  DashboardTmsLayout? _runtimeLayout;
  int? _runtimeBoardId;

  int? _lastRequestedBoardId;
  bool _isRefreshing = false;

  DashboardTmsFilter get _filter {
    return _runtimeFilter ?? DashboardTmsFilterX.fromRaw(widget.settings['filter']);
  }

  DashboardTmsLayout get _layout {
    return _runtimeLayout ?? DashboardTmsLayoutX.fromRaw(widget.settings['layout']);
  }

  int get _limit {
    final raw = widget.settings['limit'];
    final parsed = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
    return (parsed ?? 10).clamp(3, 50);
  }

  bool get _showBoardSwitcher {
    final raw = widget.settings['showBoardSwitcher'];
    if (raw is bool) return raw;
    return true;
  }

  bool get _showSyncStatus {
    final raw = widget.settings['showSyncStatus'];
    if (raw is bool) return raw;
    return true;
  }

  bool get _showStats {
    final raw = widget.settings['showStats'];
    if (raw is bool) return raw;
    return true;
  }

  bool get _compact {
    final raw = widget.settings['compact'];
    if (raw is bool) return raw;
    return false;
  }

  int? get _settingsBoardId {
    final raw = widget.settings['boardId'];
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(tmsLocalStoreProvider).init();
      await ref.read(tmsSyncServiceProvider).init();
      await ref.read(boardManagementProvider.notifier).fetchBoards(ref);
    });
  }

  int? _boardIdOf(BoardResults board) {
    final raw = board.id;
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  BoardResults? _findBoard(List<BoardResults> boards, int? id) {
    if (id == null) return null;

    for (final board in boards) {
      if (_boardIdOf(board) == id) return board;
    }

    return null;
  }

  int? _resolveBoardId({
    required List<BoardResults> boards,
    required int? selectedBoardId,
  }) {
    if (_runtimeBoardId != null) return _runtimeBoardId;
    if (_settingsBoardId != null) return _settingsBoardId;
    if (selectedBoardId != null) return selectedBoardId;
    if (boards.isNotEmpty) return _boardIdOf(boards.first);
    return null;
  }

  void _ensureBoardLoaded(int boardId) {
    if (_lastRequestedBoardId == boardId) return;
    _lastRequestedBoardId = boardId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      ref.read(boardIdProvider.notifier).state = boardId;

      await ref.read(tmsSyncServiceProvider).syncBoard(boardId);

      if (!mounted) return;

      await ref
          .read(boardDetailsManagementProvider.notifier)
          .fetchBoardDetails(boardId.toString());
    });
  }

  Future<void> _refresh({
    required int? boardId,
  }) async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await ref.read(tmsSyncServiceProvider).refreshBoards();
      await ref.read(boardManagementProvider.notifier).fetchBoards(ref);

      if (boardId != null) {
        await ref.read(tmsSyncServiceProvider).syncBoard(boardId, force: true);

        await ref
            .read(boardDetailsManagementProvider.notifier)
            .fetchBoardDetails(boardId.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  DashboardTmsLayout _resolveLayout(BoxConstraints constraints) {
    final configured = _layout;

    if (configured != DashboardTmsLayout.auto) {
      return configured;
    }

    if (widget.isMobile) {
      return DashboardTmsLayout.vertical;
    }

    final canUseHorizontal =
        constraints.maxWidth >= 720 && constraints.maxHeight >= 340;

    return canUseHorizontal
        ? DashboardTmsLayout.horizontal
        : DashboardTmsLayout.vertical;
  }

  List<Tasks> _extractTasks(BoardDetailsModel boardDetails, int? boardId) {
    if (boardId != null && boardDetails.id != null && boardDetails.id != boardId) {
      return const <Tasks>[];
    }

    final result = <Tasks>[];

    for (final progress in boardDetails.projectProgresses ?? const <ProjectProgresses>[]) {
      result.addAll(progress.tasks ?? const <Tasks>[]);
    }

    return result;
  }

  DateTime? _dateOf(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  DateTime? _updatedAtOf(Tasks task) {
    return _dateOf(task.updatedAt) ??
        _dateOf(task.timestamp) ??
        _dateOf(task.deadline);
  }

  bool _isOverdue(Tasks task) {
    if (task.isCompleted == true) return false;

    final deadline = _dateOf(task.deadline);
    if (deadline == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);

    return deadlineDay.isBefore(today);
  }

  bool _isDueSoon(Tasks task) {
    if (task.isCompleted == true) return false;

    final deadline = _dateOf(task.deadline);
    if (deadline == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final diff = deadlineDay.difference(today).inDays;

    return diff >= 0 && diff <= 7;
  }

  bool _isMine(Tasks task, int? userId) {
    if (userId == null) return false;

    if (task.assignedToUser == userId) return true;
    if (task.assignedTo == userId) return true;
    if ((task.members ?? const <int>[]).contains(userId)) return true;

    return false;
  }

  List<Tasks> _filterTasks({
    required List<Tasks> allTasks,
    required int? userId,
  }) {
    final filter = _filter;

    Iterable<Tasks> result = allTasks;

    switch (filter) {
      case DashboardTmsFilter.latest:
        break;
      case DashboardTmsFilter.mine:
        result = result.where((task) => _isMine(task, userId));
        break;
      case DashboardTmsFilter.open:
        result = result.where((task) => task.isCompleted != true);
        break;
      case DashboardTmsFilter.overdue:
        result = result.where(_isOverdue);
        break;
      case DashboardTmsFilter.dueSoon:
        result = result.where(_isDueSoon);
        break;
      case DashboardTmsFilter.completed:
        result = result.where((task) => task.isCompleted == true);
        break;
    }

    final sorted = result.toList();

    sorted.sort((a, b) {
      final ad = _updatedAtOf(a);
      final bd = _updatedAtOf(b);

      if (ad != null && bd != null) {
        final cmp = bd.compareTo(ad);
        if (cmp != 0) return cmp;
      }

      return (b.id ?? 0).compareTo(a.id ?? 0);
    });

    return sorted.take(_limit).toList(growable: false);
  }

  Future<void> _openTask(Tasks task) async {
    if (widget.isMobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.86,
            minChildSize: 0.4,
            maxChildSize: 0.96,
            expand: false,
            builder: (context, scrollController) {
              return TaskDetailsPopup(
                task: task,
                isMobile: true,
                scrollController: scrollController,
              );
            },
          );
        },
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) {
          return TaskDetailsPopup(
            task: task,
            isMobile: false,
          );
        },
      );
    }

    final boardId = ref.read(boardIdProvider);

    if (boardId != null) {
      await ref
          .read(boardDetailsManagementProvider.notifier)
          .fetchBoardDetails(boardId.toString());
    }
  }

  void _goToTms() {
    ref.read(navigationService).pushNamedScreen(Routes.proBoard);
  }

  Future<void> _showQuickAddTaskDialog({
    required int boardId,
    required BoardDetailsModel boardDetails,
  }) async {
    final progresses = boardDetails.projectProgresses ?? const <ProjectProgresses>[];

    if (progresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Create a column first.'.tr),
        ),
      );
      return;
    }

    final controller = TextEditingController();
    int selectedColumnIndex = 0;
    bool isSaving = false;

    final theme = ref.read(themeColorsProvider);

    await showDialog<void>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            final canSubmit = controller.text.trim().isNotEmpty && !isSaving;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width > 640
                    ? 520
                    : MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.dashboardBoarder,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'New task'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: TextStyle(color: theme.textColor),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Task name'.tr,
                        hintStyle: TextStyle(
                          color: theme.textColor.withAlpha(150),
                        ),
                        filled: true,
                        fillColor: theme.adPopBackground,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dashboardBoarder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.themeColor),
                        ),
                      ),
                      onSubmitted: (_) async {
                        if (!canSubmit) return;

                        setState(() => isSaving = true);

                        await ref.read(taskProvider.notifier).addTask(
                              controller.text.trim(),
                              selectedColumnIndex,
                              boardId.toString(),
                            );

                        await ref
                            .read(boardDetailsManagementProvider.notifier)
                            .fetchBoardDetails(boardId.toString());

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      value: selectedColumnIndex,
                      dropdownColor: theme.adPopBackground,
                      decoration: InputDecoration(
                        labelText: 'Column'.tr,
                        labelStyle: TextStyle(color: theme.textColor),
                        filled: true,
                        fillColor: theme.adPopBackground,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dashboardBoarder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.themeColor),
                        ),
                      ),
                      items: List.generate(progresses.length, (index) {
                        final progress = progresses[index];

                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(
                            progress.name ?? 'Column ${progress.id}',
                            style: TextStyle(color: theme.textColor),
                          ),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedColumnIndex = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.dashboardBoarder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancel'.tr,
                              style: TextStyle(color: theme.textColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.themeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: canSubmit
                                ? () async {
                                    setState(() => isSaving = true);

                                    await ref.read(taskProvider.notifier).addTask(
                                          controller.text.trim(),
                                          selectedColumnIndex,
                                          boardId.toString(),
                                        );

                                    await ref
                                        .read(
                                          boardDetailsManagementProvider.notifier,
                                        )
                                        .fetchBoardDetails(boardId.toString());

                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                : null,
                            child: isSaving
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.themeTextColor,
                                    ),
                                  )
                                : Text(
                                    'Create'.tr,
                                    style: TextStyle(
                                      color: theme.themeTextColor,
                                    ),
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
        );
      },
    );

    controller.dispose();
  }

  void _showCreateBoardDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => const CreateTodoBoardDialogWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final boardData = ref.watch(boardManagementProvider);
    final selectedBoardId = ref.watch(boardIdProvider);
    final boardDetails = ref.watch(boardDetailsStateProvider);
    final userId = ref.watch(userProvider).maybeWhen(
          data: (user) => user?.idInt,
          orElse: () => null,
        );

    final boards = boardData.results ?? const <BoardResults>[];
    final currentBoardId = _resolveBoardId(
      boards: boards,
      selectedBoardId: selectedBoardId,
    );

    if (currentBoardId != null) {
      _ensureBoardLoaded(currentBoardId);
    }

    final currentBoard = _findBoard(boards, currentBoardId);
    final allTasks = _extractTasks(boardDetails, currentBoardId);
    final visibleTasks = _filterTasks(
      allTasks: allTasks,
      userId: userId,
    );

    final openCount = allTasks.where((task) => task.isCompleted != true).length;
    final completedCount = allTasks.where((task) => task.isCompleted == true).length;
    final overdueCount = allTasks.where(_isOverdue).length;
    final dueSoonCount = allTasks.where(_isDueSoon).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedLayout = _resolveLayout(constraints);
        final compact = _compact || constraints.maxHeight < 390;

        return Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dashboardBoarder,
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                _TmsDashboardHeader(
                  theme: theme,
                  filter: _filter,
                  layout: _layout,
                  compact: compact,
                  isRefreshing: _isRefreshing,
                  onFilterChanged: (value) {
                    setState(() => _runtimeFilter = value);
                  },
                  onLayoutChanged: (value) {
                    setState(() => _runtimeLayout = value);
                  },
                  onRefresh: () => _refresh(boardId: currentBoardId),
                  onGoToTms: _goToTms,
                  onNewBoard: _showCreateBoardDialog,
                  onNewTask: currentBoardId == null
                      ? null
                      : () => _showQuickAddTaskDialog(
                            boardId: currentBoardId,
                            boardDetails: boardDetails,
                          ),
                ),
                if (_showBoardSwitcher)
                  _TmsBoardSwitcher(
                    theme: theme,
                    boards: boards,
                    selectedBoardId: currentBoardId,
                    compact: compact,
                    onChanged: (boardId) {
                      setState(() {
                        _runtimeBoardId = boardId;
                        _lastRequestedBoardId = null;
                      });
                    },
                  ),
                if (_showSyncStatus)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 12,
                      vertical: compact ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.adPopBackground.withAlpha(90),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dashboardBoarder.withAlpha(120),
                        ),
                      ),
                    ),
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: TmsSyncStatusChip(),
                    ),
                  ),
                if (_showStats && !compact)
                  _TmsStatsRow(
                    theme: theme,
                    openCount: openCount,
                    completedCount: completedCount,
                    overdueCount: overdueCount,
                    dueSoonCount: dueSoonCount,
                  ),
                Expanded(
                  child: resolvedLayout == DashboardTmsLayout.horizontal &&
                          !widget.isMobile
                      ? Row(
                          children: [
                            SizedBox(
                              width: constraints.maxWidth * 0.42,
                              child: _TmsBoardSummaryPanel(
                                theme: theme,
                                board: currentBoard,
                                boardDetails: boardDetails,
                                allTasks: allTasks,
                                compact: compact,
                              ),
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: theme.dashboardBoarder,
                            ),
                            Expanded(
                              child: _TmsTaskList(
                                theme: theme,
                                tasks: visibleTasks,
                                compact: compact,
                                onOpenTask: _openTask,
                              ),
                            ),
                          ],
                        )
                      : _TmsTaskList(
                          theme: theme,
                          tasks: visibleTasks,
                          compact: compact,
                          onOpenTask: _openTask,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TmsDashboardHeader extends StatelessWidget {
  final ThemeColors theme;
  final DashboardTmsFilter filter;
  final DashboardTmsLayout layout;
  final bool compact;
  final bool isRefreshing;
  final ValueChanged<DashboardTmsFilter> onFilterChanged;
  final ValueChanged<DashboardTmsLayout> onLayoutChanged;
  final VoidCallback onRefresh;
  final VoidCallback onGoToTms;
  final VoidCallback onNewBoard;
  final VoidCallback? onNewTask;

  const _TmsDashboardHeader({
    required this.theme,
    required this.filter,
    required this.layout,
    required this.compact,
    required this.isRefreshing,
    required this.onFilterChanged,
    required this.onLayoutChanged,
    required this.onRefresh,
    required this.onGoToTms,
    required this.onNewBoard,
    required this.onNewTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 56 : 66,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(
          bottom: BorderSide(
            color: theme.dashboardBoarder.withAlpha(160),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 34 : 42,
            height: compact ? 34 : 42,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.themeColor.withAlpha(80),
              ),
            ),
            child: Icon(
              Icons.fact_check_outlined,
              color: theme.themeColor,
              size: compact ? 18 : 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: compact
                ? Text(
                    'TMS'.tr,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'TMS'.tr,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        filter.label.tr,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(165),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
          _TmsPopupButton<DashboardTmsFilter>(
            theme: theme,
            tooltip: 'Filter'.tr,
            icon: filter.icon,
            selected: filter,
            items: DashboardTmsFilter.values,
            labelBuilder: (item) => item.label.tr,
            iconBuilder: (item) => item.icon,
            onSelected: onFilterChanged,
          ),
          const SizedBox(width: 6),
          _TmsPopupButton<DashboardTmsLayout>(
            theme: theme,
            tooltip: 'Layout'.tr,
            icon: layout.icon,
            selected: layout,
            items: DashboardTmsLayout.values,
            labelBuilder: (item) => item.label.tr,
            iconBuilder: (item) => item.icon,
            onSelected: onLayoutChanged,
          ),
          const SizedBox(width: 6),
          _TmsHeaderIconButton(
            theme: theme,
            tooltip: 'Refresh'.tr,
            icon: Icons.refresh_rounded,
            isLoading: isRefreshing,
            onTap: isRefreshing ? null : onRefresh,
          ),
          const SizedBox(width: 6),
          _TmsHeaderIconButton(
            theme: theme,
            tooltip: 'Go to TMS'.tr,
            icon: Icons.open_in_new_rounded,
            onTap: onGoToTms,
          ),
          const SizedBox(width: 6),
          _TmsHeaderIconButton(
            theme: theme,
            tooltip: 'New board'.tr,
            icon: Icons.dashboard_customize_outlined,
            onTap: onNewBoard,
          ),
          const SizedBox(width: 6),
          _TmsHeaderIconButton(
            theme: theme,
            tooltip: 'New task'.tr,
            icon: Icons.add_rounded,
            filled: true,
            onTap: onNewTask,
          ),
        ],
      ),
    );
  }
}

class _TmsHeaderIconButton extends StatelessWidget {
  final ThemeColors theme;
  final String tooltip;
  final IconData icon;
  final bool filled;
  final bool isLoading;
  final VoidCallback? onTap;

  const _TmsHeaderIconButton({
    required this.theme,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? theme.themeColor : theme.adPopBackground;
    final fg = filled ? theme.themeTextColor : theme.textColor;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: filled
                  ? theme.themeColor.withAlpha(160)
                  : theme.dashboardBoarder.withAlpha(150),
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                : Icon(icon, color: fg, size: 18),
          ),
        ),
      ),
    );
  }
}

class _TmsPopupButton<T> extends StatelessWidget {
  final ThemeColors theme;
  final String tooltip;
  final IconData icon;
  final T selected;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final IconData Function(T item) iconBuilder;
  final ValueChanged<T> onSelected;

  const _TmsPopupButton({
    required this.theme,
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.items,
    required this.labelBuilder,
    required this.iconBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PopupMenuButton<T>(
        color: theme.adPopBackground,
        tooltip: tooltip,
        onSelected: onSelected,
        itemBuilder: (_) {
          return items.map((item) {
            final isSelected = item == selected;

            return PopupMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  Icon(
                    iconBuilder(item),
                    size: 17,
                    color: isSelected ? theme.themeColor : theme.textColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      labelBuilder(item),
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: theme.themeColor,
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.dashboardBoarder.withAlpha(150),
            ),
          ),
          child: Icon(icon, color: theme.textColor, size: 18),
        ),
      ),
    );
  }
}

class _TmsBoardSwitcher extends StatelessWidget {
  final ThemeColors theme;
  final List<BoardResults> boards;
  final int? selectedBoardId;
  final bool compact;
  final ValueChanged<int> onChanged;

  const _TmsBoardSwitcher({
    required this.theme,
    required this.boards,
    required this.selectedBoardId,
    required this.compact,
    required this.onChanged,
  });

  int? _boardIdOf(BoardResults board) {
    final raw = board.id;
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 42 : 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(120),
        border: Border(
          bottom: BorderSide(
            color: theme.dashboardBoarder.withAlpha(130),
          ),
        ),
      ),
      child: boards.isEmpty
          ? Row(
              children: [
                Icon(
                  Icons.dashboard_outlined,
                  size: 16,
                  color: theme.textColor.withAlpha(170),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No boards yet'.tr,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(170),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: selectedBoardId,
                dropdownColor: theme.adPopBackground,
                borderRadius: BorderRadius.circular(12),
                icon: Icon(Icons.expand_more_rounded, color: theme.textColor),
                items: boards
                    .map((board) {
                      final id = _boardIdOf(board);
                      if (id == null) return null;

                      return DropdownMenuItem<int>(
                        value: id,
                        child: Row(
                          children: [
                            Icon(
                              Icons.dashboard_customize_outlined,
                              color: theme.themeColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                board.name ?? 'Board $id',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .whereType<DropdownMenuItem<int>>()
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  onChanged(value);
                },
              ),
            ),
    );
  }
}

class _TmsStatsRow extends StatelessWidget {
  final ThemeColors theme;
  final int openCount;
  final int completedCount;
  final int overdueCount;
  final int dueSoonCount;

  const _TmsStatsRow({
    required this.theme,
    required this.openCount,
    required this.completedCount,
    required this.overdueCount,
    required this.dueSoonCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dashboardBoarder.withAlpha(120),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TmsStatChip(
              theme: theme,
              label: 'Open'.tr,
              value: openCount,
              icon: Icons.radio_button_unchecked_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TmsStatChip(
              theme: theme,
              label: 'Soon'.tr,
              value: dueSoonCount,
              icon: Icons.event_available_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TmsStatChip(
              theme: theme,
              label: 'Late'.tr,
              value: overdueCount,
              icon: Icons.warning_amber_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TmsStatChip(
              theme: theme,
              label: 'Done'.tr,
              value: completedCount,
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _TmsStatChip extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final int value;
  final IconData icon;

  const _TmsStatChip({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(135),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.themeColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TmsBoardSummaryPanel extends StatelessWidget {
  final ThemeColors theme;
  final BoardResults? board;
  final BoardDetailsModel boardDetails;
  final List<Tasks> allTasks;
  final bool compact;

  const _TmsBoardSummaryPanel({
    required this.theme,
    required this.board,
    required this.boardDetails,
    required this.allTasks,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final progresses = boardDetails.projectProgresses ?? const <ProjectProgresses>[];

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 14),
        decoration: BoxDecoration(
          color: theme.adPopBackground.withAlpha(130),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dashboardBoarder.withAlpha(140),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((board?.avatar ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: Image.network(
                    board!.avatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            if ((board?.avatar ?? '').isNotEmpty) const SizedBox(height: 12),
            Text(
              board?.name ?? 'Board'.tr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progresses.length} ${"columns".tr} • ${allTasks.length} ${"tasks".tr}',
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: progresses.isEmpty
                  ? Center(
                      child: Text(
                        'No columns yet'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(160),
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: progresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final progress = progresses[index];
                        final count = progress.tasks?.length ?? 0;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: theme.dashboardContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.dashboardBoarder.withAlpha(120),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  progress.name ?? 'Column ${progress.id}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.themeColor.withAlpha(22),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  count.toString(),
                                  style: TextStyle(
                                    color: theme.themeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TmsTaskList extends StatelessWidget {
  final ThemeColors theme;
  final List<Tasks> tasks;
  final bool compact;
  final ValueChanged<Tasks> onOpenTask;

  const _TmsTaskList({
    required this.theme,
    required this.tasks,
    required this.compact,
    required this.onOpenTask,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fact_check_outlined,
                size: 38,
                color: theme.textColor.withAlpha(110),
              ),
              const SizedBox(height: 10),
              Text(
                'No tasks to show'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textColor.withAlpha(170),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(compact ? 8 : 10),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => SizedBox(height: compact ? 6 : 8),
      itemBuilder: (context, index) {
        final task = tasks[index];

        return _TmsTaskTile(
          theme: theme,
          task: task,
          compact: compact,
          onTap: () => onOpenTask(task),
        );
      },
    );
  }
}

class _TmsTaskTile extends StatelessWidget {
  final ThemeColors theme;
  final Tasks task;
  final bool compact;
  final VoidCallback onTap;

  const _TmsTaskTile({
    required this.theme,
    required this.task,
    required this.compact,
    required this.onTap,
  });

  DateTime? _dateOf(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month';
  }

  bool _isOverdue() {
    if (task.isCompleted == true) return false;

    final deadline = _dateOf(task.deadline);
    if (deadline == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);

    return deadlineDay.isBefore(today);
  }

  bool _isDueSoon() {
    if (task.isCompleted == true) return false;

    final deadline = _dateOf(task.deadline);
    if (deadline == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final diff = deadlineDay.difference(today).inDays;

    return diff >= 0 && diff <= 7;
  }

  int _totalChecklistItems() {
    var total = 0;

    for (final checklist in task.tmsTaskChecklist ?? const <TaskChecklist>[]) {
      total += checklist.checklist.length;
    }

    return total;
  }

  int _completedChecklistItems() {
    var total = 0;

    for (final checklist in task.tmsTaskChecklist ?? const <TaskChecklist>[]) {
      total += checklist.checklist.where((item) => item.completed).length;
    }

    return total;
  }

  String _priorityLabel(String? raw) {
    switch (raw) {
      case 'H':
        return 'High';
      case 'M':
        return 'Medium';
      case 'L':
        return 'Low';
      default:
        return '';
    }
  }

  Color _priorityColor(String? raw) {
    switch (raw) {
      case 'H':
        return Colors.redAccent;
      case 'M':
        return Colors.orangeAccent;
      case 'L':
        return Colors.green;
      default:
        return theme.themeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadline = _dateOf(task.deadline);
    final isCompleted = task.isCompleted == true;
    final isOverdue = _isOverdue();
    final isDueSoon = _isDueSoon();
    final checklistTotal = _totalChecklistItems();
    final checklistDone = _completedChecklistItems();
    final priority = _priorityLabel(task.priority);

    final accent = isCompleted
        ? Colors.green
        : isOverdue
            ? Colors.redAccent
            : isDueSoon
                ? Colors.amber
                : theme.themeColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(isCompleted ? 125 : 210),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withAlpha(isCompleted ? 90 : 120),
          width: isOverdue ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 9 : 11,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 30 : 34,
                  height: compact ? 30 : 34,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_outline_rounded
                        : Icons.task_alt_outlined,
                    color: accent,
                    size: compact ? 16 : 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name ?? 'Task'.tr,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCompleted
                              ? theme.textColor.withAlpha(145)
                              : theme.textColor,
                          fontSize: compact ? 12 : 13,
                          fontWeight:
                              isCompleted ? FontWeight.w500 : FontWeight.w800,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      if (!compact && (task.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor.withAlpha(135),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (priority.isNotEmpty)
                            _TmsMiniChip(
                              theme: theme,
                              label: priority.tr,
                              icon: Icons.flag_rounded,
                              color: _priorityColor(task.priority),
                            ),
                          if (deadline != null)
                            _TmsMiniChip(
                              theme: theme,
                              label: _formatDate(deadline),
                              icon: Icons.access_time_rounded,
                              color: accent,
                            ),
                          if ((task.commentsCount ?? 0) > 0)
                            _TmsMiniChip(
                              theme: theme,
                              label: '${task.commentsCount}',
                              icon: Icons.comment_outlined,
                              color: theme.themeColor,
                            ),
                          if (checklistTotal > 0)
                            _TmsMiniChip(
                              theme: theme,
                              label: '$checklistDone/$checklistTotal',
                              icon: Icons.check_box_outlined,
                              color: theme.themeColor,
                            ),
                          if ((task.members ?? const <int>[]).isNotEmpty)
                            _TmsMiniChip(
                              theme: theme,
                              label: '${task.members!.length}',
                              icon: Icons.group_outlined,
                              color: theme.themeColor,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TmsMiniChip extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final IconData icon;
  final Color color;

  const _TmsMiniChip({
    required this.theme,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withAlpha(70),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.textColor.withAlpha(195),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}