import 'dart:ui' as ui;

import 'package:automation/src/widgets/popup/automation_context_launcher.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:crm/widget/add_task_modal_sheet_widget.dart';
import 'package:crm/widget/create_todo_board_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:tms_app/todo/local/tms_local_store.dart';
import 'package:tms_app/todo/models/get_user_board_model.dart';
import 'package:tms_app/todo/provider/filtered_tasks_provider.dart';
import 'package:tms_app/todo/provider/todo_pie_menu.dart';
import 'package:tms_app/todo/view/widgets/task_filters_dialog.dart';

import 'board/provider/board_details_provider.dart';
import 'board/provider/board_provider.dart';
import 'view/crm_tms_board.dart';

import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';

final isDropdownExpandedProvider = StateProvider<bool>((ref) => false);

class ToDoMobile extends ConsumerStatefulWidget {
  final AppModule appModule;

  const ToDoMobile({
    super.key,
    this.appModule = AppModule.agentCrm,
  });

  @override
  ConsumerState<ToDoMobile> createState() => _ToDoMobileState();
}

class _ToDoMobileState extends ConsumerState<ToDoMobile> with TickerProviderStateMixin {
  final GlobalKey<SideMenuState> sideMenuKey = GlobalKey<SideMenuState>();

  late final ProviderSubscription<BoardModel> _boardsSub;
  int? _lastFetchedBoardId;

  late final AnimationController _boardStripCtrl;
  late final Animation<double> _boardStripAnim;

  @override
  void initState() {
    super.initState();

    _boardStripCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _boardStripAnim = CurvedAnimation(
      parent: _boardStripCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _boardsSub = ref.listenManual<BoardModel>(
      boardManagementProvider,
      (previous, next) {
        final results = next.results ?? const [];

        if (results.isEmpty) return;

        final currentBoardId = ref.read(boardIdProvider);

        final hasCurrent = currentBoardId != null &&
            results.any((board) => board.id == currentBoardId);

        if (!hasCurrent) {
          final firstBoardId = results.first.id;

          if (firstBoardId != null) {
            _selectBoard(firstBoardId, forceFetch: true);
          }

          return;
        }

        if (_lastFetchedBoardId != currentBoardId) {
          _selectBoard(currentBoardId, forceFetch: true);
        }
      },
    );

    Future.microtask(() async {
      await ref.read(tmsLocalStoreProvider).init();
      await ref.read(boardManagementProvider.notifier).fetchBoards(ref);
    });
  }

  @override
  void dispose() {
    _boardStripCtrl.dispose();
    _boardsSub.close();
    super.dispose();
  }

  void _showBoardStrip() {
    if (!_boardStripCtrl.isCompleted) _boardStripCtrl.forward();
  }

  void _hideBoardStrip() {
    if (!_boardStripCtrl.isDismissed) _boardStripCtrl.reverse();
  }

  void _toggleBoardStrip() {
    if (_boardStripCtrl.value > 0.5) {
      _boardStripCtrl.reverse();
    } else {
      _boardStripCtrl.forward();
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    // OverscrollNotification only fires with ClampingScrollPhysics (Android).
    // On iOS, BouncingScrollPhysics never reports an overscroll delta -- the
    // rubber-band drag shows up as a plain ScrollUpdateNotification with
    // pixels pushed below minScrollExtent, so we must also check for that.
    final isPullingDown =
        (notification is OverscrollNotification && notification.overscroll < 0) ||
            (notification is ScrollUpdateNotification &&
                notification.metrics.pixels < notification.metrics.minScrollExtent);

    if (isPullingDown) {
      _showBoardStrip();
    } else if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (notification.metrics.pixels > 30 && delta > 0) {
        _hideBoardStrip();
      }
    }
    return false;
  }

  Widget _buildBoardsHandle(dynamic theme, BoardResults? currentBoard) {
    final name = (currentBoard?.name ?? '').trim();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleBoardStrip,
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 15,
                color: theme.textColor.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                name.isEmpty ? 'Boards' : name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor.withOpacity(0.8),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _boardStripAnim,
                builder: (_, __) => Transform.rotate(
                  angle: _boardStripAnim.value * 3.14159,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: theme.textColor.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectBoard(
    int boardId, {
    bool forceFetch = false,
  }) async {
    final currentBoardId = ref.read(boardIdProvider);

    ref.read(boardIdProvider.notifier).state = boardId;

    final shouldFetch =
        forceFetch ||
        _lastFetchedBoardId != boardId ||
        currentBoardId != boardId;

    if (!shouldFetch) return;

    _lastFetchedBoardId = boardId;

    await ref
        .read(boardDetailsManagementProvider.notifier)
        .fetchBoardDetails(boardId.toString());
  }

  void _openCreateBoardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const CreateTodoBoardDialogWidget(),
    );
  }

  void _openAddTaskSheet(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 20,
                  sigmaY: 20,
                ),
                child: Container(
                  color: theme.textFieldColor.withAlpha((255 * 0.35).toInt()),
                  child: AddTaskModalSheetWidget(
                    scrollController: scrollController,
                    clientId: '',
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openFiltersSheet(BuildContext context) {
    final theme = ref.read(themeColorsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(6),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: true,
          builder: (ctx, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 20,
                  sigmaY: 20,
                ),
                child: Container(
                  color: theme.textFieldColor.withAlpha((255 * 0.35).toInt()),
                  child: TaskFiltersDialog(
                    isMobile: true,
                    scrollController: scrollController,
                    onApply: () async {
                      final projectId = ref.read(boardIdProvider);

                      if (projectId == null) return;

                      await ref
                          .read(filteredTasksProvider.notifier)
                          .fetchForProject(projectId);
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBoardAvatar({
    required String name,
    required String avatar,
    required bool isSelected,
    required dynamic theme,
  }) {
    final initials = name.isEmpty
        ? 'B'
        : name
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .take(2)
            .map((e) => e[0].toUpperCase())
            .join();

    final useNetworkAvatar = avatar.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: theme.textFieldColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.themeColor
              : theme.dashboardBoarder.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.dashboardBoarder,
            child: ClipOval(
              child: useNetworkAvatar
                  ? Image.network(
                      avatar,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      cacheWidth: 88,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, __, ___) {
                        return Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name.isEmpty ? 'Board' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: theme.textColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBoardTile(BuildContext context, dynamic theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: SizedBox(
        width: 70,
        height: 80,
        child: EmmaUiAnchorTarget(
  // @emma-backend: EmmaAnchors.tmsTodoMobileAddBoardTile
  anchorKey: 'tms.todo.mobile.add_board_tile',
  child: InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => _openCreateBoardDialog(context),
    child: Container(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: theme.textFieldColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dashboardBoarder.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.dashboardBoarder,
            child: Icon(
              Icons.add,
              color: theme.textColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: theme.textColor.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  ),
),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardData = ref.watch(boardManagementProvider);
    final selectedBoardId = ref.watch(boardIdProvider);
    final theme = ref.watch(themeColorsProvider);

    final boards = boardData.results ?? const [];
    final hasBoards = boards.isNotEmpty;
    final hasSelectedBoard = selectedBoardId != null;

    BoardResults? currentBoard;
    for (final board in boards) {
      if (board.id == selectedBoardId) {
        currentBoard = board;
        break;
      }
    }

return EmmaUiAnchorTarget(
  // @emma-backend: EmmaAnchors.tmsTodoMobileRoot
  anchorKey: 'tms.todo.mobile.root',
  runtimeMode: EmmaUiAnchorRuntimeMode.always,
  tapMode: EmmaUiAnchorTapMode.disabled,
  child: BarManager(
    showClientToggle: true,
    sideMenuKey: sideMenuKey,
    appModule: widget.appModule,
    enableScrool: true,
    verticalButtons: Column(
      spacing: 4,
      children: [
        EmmaUiAnchorTarget(
          // @emma-backend: EmmaAnchors.tmsTodoMobileFilterButton
          anchorKey: 'tms.todo.mobile.filter_button',
          child: SizedBox(
            height: 40,
            width: 40,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10.copyWith(
                backgroundColor: WidgetStatePropertyAll(
                  theme.adPopBackground,
                ),
              ),
              onPressed: () => _openFiltersSheet(context),
              child: Icon(
                Icons.filter_list_alt,
                color: theme.textColor,
              ),
            ),
          ),
        ),
        if (selectedBoardId != null)
          EmmaUiAnchorTarget(
            anchorKey: 'tms.todo.mobile.automation_button',
            child: SizedBox(
              height: 40,
              width: 40,
              child: ElevatedButton(
                style: elevatedButtonStyleRounded10.copyWith(
                  backgroundColor: WidgetStatePropertyAll(
                    theme.adPopBackground,
                  ),
                ),
                onPressed: () => openTmsBoardAutomationStudioSheet(
                  theme,
                  context,
                  boardId: selectedBoardId.toString(),
                  boardName: (currentBoard?.name ?? 'TMS Board').toString(),
                ),
                child: Icon(
                  Icons.auto_awesome_motion_rounded,
                  color: theme.textColor,
                ),
              ),
            ),
          ),
        EmmaUiAnchorTarget(
          // @emma-backend: EmmaAnchors.tmsTodoMobileAddTaskButton
          anchorKey: 'tms.todo.mobile.add_task_button',
          child: SizedBox(
            height: 40,
            width: 40,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10.copyWith(
                backgroundColor: WidgetStatePropertyAll(
                  theme.adPopBackground,
                ),
              ),
              onPressed: () => _openAddTaskSheet(context),
              child: AppIcons.add(color: theme.textColor),
            ),
          ),
        ),
      ],
    ),
    childMobile: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: TopAppBarSize.resolve(context) + 5),
        _buildBoardsHandle(theme, currentBoard),
        SizeTransition(
          sizeFactor: _boardStripAnim,
          axisAlignment: -1,
          child: EmmaUiAnchorTarget(
            // @emma-backend: EmmaAnchors.tmsTodoMobileBoardStrip
            anchorKey: 'tms.todo.mobile.board_strip',
            tapMode: EmmaUiAnchorTapMode.disabled,
            child: SizedBox(
              height: 110,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: boards.length + 1,
                itemBuilder: (context, index) {
                  final isAddTile = index == boards.length;

                  if (isAddTile) {
                    return _buildAddBoardTile(context, theme);
                  }

                  final data = boards[index];
                  final boardId = data.id;
                  if (boardId == null) {
                    return const SizedBox.shrink();
                  }

                  final isSelected = boardId == selectedBoardId;
                  final name = (data.name ?? '').trim();
                  final rawAvatar = (data.avatar ?? '').trim();

                  return PieMenu(
                    theme: PieTheme.of(context).copyWith(
                      overlayColor: theme.textColor.computeLuminance() > 0.5
                          ? Colors.black.withValues(alpha: 0.70)
                          : Colors.white.withValues(alpha: 0.70),
                    ),
                    key: ValueKey(boardId),
                    actions: buildPieMenuActionsTodo(
                      context,
                      ref,
                      boardId.toString(),
                      theme,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _selectBoard(boardId);
                          _hideBoardStrip();
                        },
                        child: SizedBox(
                          width: 70,
                          height: 80,
                          child: _buildBoardAvatar(
                            name: name,
                            avatar: rawAvatar,
                            isSelected: isSelected,
                            theme: theme,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: !hasBoards
              ? Center(
                  child: Text(
                    'No boards yet',
                    style: TextStyle(
                      color: theme.textColor.withOpacity(0.8),
                    ),
                  ),
                )
              : hasSelectedBoard
                  ? NotificationListener<ScrollNotification>(
                      onNotification: _onScrollNotification,
                      child: const CrmToDoBoard(isMobile: true),
                    )
                  : Center(
                      child: CircularProgressIndicator(
                        color: theme.themeColor,
                      ),
                    ),
        ),
        SizedBox(height: BottomBarSize.resolve(context)),
      ],
    ),
  ),
);
  }
}