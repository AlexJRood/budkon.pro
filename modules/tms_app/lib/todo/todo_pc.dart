// tms_app/todo/todo_pc.dart

import 'dart:ui';

import 'package:automation/src/widgets/popup/automation_context_launcher.dart';
import 'package:core/shell/manager/bar_manager.dart';
import 'package:crm/widget/create_todo_board_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:tms_app/todo/models/get_user_board_model.dart';
import 'package:tms_app/todo/provider/filtered_tasks_provider.dart';
import 'package:tms_app/todo/provider/todo_pie_menu.dart';
import 'package:tms_app/todo/view/widgets/task_filters_dialog.dart';
import 'view/crm_tms_board.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'board/provider/board_details_provider.dart';
import 'board/provider/board_provider.dart';
import 'dart:ui' as ui;
import 'package:tms_app/todo/local/tms_local_store.dart';
import 'package:tms_app/todo/view/widgets/tms_sync_status_chip.dart';

import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';

class ToDoPc extends ConsumerStatefulWidget {
  final AppModule appModule;
  const ToDoPc({super.key, this.appModule = AppModule.agentCrm});

  @override
  ConsumerState<ToDoPc> createState() => _ToDoPcState();
}

class _ToDoPcState extends ConsumerState<ToDoPc> {
  late final ScrollController scrollControllerVertical;

  @override
  void initState() {
    super.initState();
    scrollControllerVertical = ScrollController();

    Future.microtask(() async {
      await ref.read(tmsLocalStoreProvider).init();
      await ref.read(boardManagementProvider.notifier).fetchBoards(ref);

      final boards = ref.read(boardManagementProvider).results ?? [];
      final selectedId = ref.read(boardIdProvider);

      if (selectedId == null && boards.isNotEmpty) {
        ref.read(boardIdProvider.notifier).state = boards.first.id;
      }
    });
  }

  @override
  void dispose() {
    scrollControllerVertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardData = ref.watch(boardManagementProvider);
    final boardsOrder = ref.watch(boardsOrderProvider);
    final sideMenuKey = GlobalKey<SideMenuState>();
    final selectedBoardId = ref.watch(boardIdProvider);
    final theme = ref.read(themeColorsProvider);

    final results = boardData.results ?? [];

    // 🔹 Keep provider list in sync with backend results length
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(boardsOrderProvider.notifier);
      final current = notifier.state;

      final shouldSync =
          current.length != results.length ||
              current.any((oldBoard) {
                final fresh = results.firstWhereOrNull((b) => b.id == oldBoard.id);
                return fresh == null ||
                    fresh.name != oldBoard.name ||
                    fresh.avatar != oldBoard.avatar;
              });

      if (shouldSync) {
        notifier.state = List<BoardResults>.of(results);
      }
    });

    // 🔹 Use ordered list if present, otherwise fall back to backend list
    final List<BoardResults> boards =
        boardsOrder.isNotEmpty ? boardsOrder : results;
        
    final currentBoard = boardData.results?.firstWhereOrNull(
      (b) => b.id == selectedBoardId,
    );

    // Back to normal BarManager (PieCanvas is in ToDoPage)
    return EmmaUiAnchorTarget(
  // @emma-backend: EmmaAnchors.tmsTodoPcRoot
  anchorKey: 'tms.todo.pc.root',
  runtimeMode: EmmaUiAnchorRuntimeMode.always,
  tapMode: EmmaUiAnchorTapMode.disabled,
  child: BarManager(
    sideMenuKey: sideMenuKey,
    appModule: widget.appModule,
    isTopAppBarHoveroverUI: false,
    childrenPc: [
      Expanded(
        child: EmmaUiAnchorTarget(
          // @emma-backend: EmmaAnchors.tmsTodoBoardRoot
          anchorKey: 'tms.todo.board.root',
          runtimeMode: EmmaUiAnchorRuntimeMode.always,
          tapMode: EmmaUiAnchorTapMode.disabled,
          child: Container(
            decoration: BoxDecoration(
              image: (currentBoard?.avatar?.isNotEmpty ?? false)
                  ? DecorationImage(
                      image: NetworkImage(currentBoard!.avatar!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Row(
              children: [
                EmmaUiAnchorTarget(
                  // @emma-backend: EmmaAnchors.tmsTodoPcBoardSidebar
                  anchorKey: 'tms.todo.pc.board_sidebar',
                  tapMode: EmmaUiAnchorTapMode.disabled,
                  child: Container(
                    width: 120,
                    color: theme.popupcontainercolor.withAlpha(120),
                    child: Column(
                      spacing: 12,
                      children: [
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: EmmaUiAnchorTarget(
                            // @emma-backend: EmmaAnchors.tmsTodoPcSyncStatus
                            anchorKey: 'tms.todo.pc.sync_status',
                            tapMode: EmmaUiAnchorTapMode.disabled,
                            child: TmsSyncStatusChip(),
                          ),
                        ),

                        SizedBox(
                          height: 48,
                          child: EmmaUiAnchorTarget(
                            // @emma-backend: EmmaAnchors.tmsTodoPcAllBoardsButton
                            anchorKey: 'tms.todo.pc.all_boards_button',
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: theme.dashboardContainer,
                                foregroundColor: theme.textColor,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: theme.dashboardBoarder),
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(navigationService)
                                    .pushNamedScreen(Routes.proBoard);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.apps, size: 18, color: theme.textColor),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'All Boards'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: theme.textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: EmmaUiAnchorTarget(
                            // @emma-backend: EmmaAnchors.tmsTodoPcBoardList
                            anchorKey: 'tms.todo.pc.board_list',
                            tapMode: EmmaUiAnchorTapMode.disabled,
                            child: ReorderableListView.builder(
                              key: const PageStorageKey('boardListView'),
                              scrollController: scrollControllerVertical,
                              scrollDirection: Axis.vertical,
                              itemCount: boards.length,
                              onReorder: (oldIndex, newIndex) async {
                                ref.read(boardsOrderProvider.notifier).update((state) {
                                  final list = List.of(
                                    state.isNotEmpty ? state : results,
                                  );
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  final movedItem = list.removeAt(oldIndex);
                                  list.insert(newIndex, movedItem);
                                  return list;
                                });

                                final orderedIds = ref
                                    .read(boardsOrderProvider)
                                    .map((b) => b.id as int)
                                    .toList();

                                await ref
                                    .read(boardManagementProvider.notifier)
                                    .reorderProjects(orderedIds);
                              },
                              itemBuilder: (context, index) {
                                final data = boards[index];
                                final isSelected = data.id == selectedBoardId;

                                return PieMenu(
                                  theme: PieTheme.of(context).copyWith(
                                    overlayColor: (() {
                                      final theme = ref.watch(themeColorsProvider);
                                      final bool uiIsDark =
                                          theme.textColor.computeLuminance() > 0.5;

                                      final base =
                                          uiIsDark ? Colors.black : Colors.white;
                                      return base.withValues(alpha: 0.70);
                                    })(),
                                  ),
                                  key: ValueKey(data.id),
                                  actions: buildPieMenuActionsTodo(
                                    context,
                                    ref,
                                    data.id.toString(),
                                    theme,
                                  ),
                                  child: Padding(
                                    key: ValueKey(data.id),
                                    padding: const EdgeInsets.only(
                                      bottom: 10,
                                      left: 5,
                                      right: 0,
                                    ),
                                    child: ElevatedButton(
                                      style: elevatedButtonStyleRounded10withoutPadding,
                                      onPressed: () {
                                        ref.read(boardIdProvider.notifier).state = data.id;
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color.fromRGBO(
                                                  255,
                                                  255,
                                                  255,
                                                  0.2,
                                                )
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          border: isSelected
                                              ? Border.all(
                                                  color: const Color.fromRGBO(
                                                    145,
                                                    145,
                                                    145,
                                                    1,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0,
                                            vertical: 15,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                    sigmaX: isSelected ? 0 : 5,
                                                    sigmaY: isSelected ? 0 : 5,
                                                  ),
                                                  child: Container(
                                                    height: 80,
                                                    width: 80,
                                                    decoration: BoxDecoration(
                                                      image: data.avatar != null &&
                                                              data.avatar!.isNotEmpty
                                                          ? DecorationImage(
                                                              image: NetworkImage(
                                                                data.avatar!,
                                                              ),
                                                              fit: BoxFit.cover,
                                                            )
                                                          : null,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Colors.white.withAlpha(
                                                              (255 * 0.1).toInt(),
                                                            ),
                                                      borderRadius:
                                                          BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '${data.name}',
                                                style: TextStyle(
                                                  color: theme.textColor,
                                                  fontSize: 12,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        SizedBox(
                          width: 120,
                          height: 45,
                          child: EmmaUiAnchorTarget(
                            // @emma-backend: EmmaAnchors.tmsTodoPcAddBoardButton
                            anchorKey: 'tms.todo.pc.add_board_button',
                            child: ElevatedButton(
                              style: elevatedButtonStyleRounded10,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      const CreateTodoBoardDialogWidget(),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  AppIcons.add(
                                    color: theme.textColor,
                                    height: 16,
                                    width: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'ADD BOARD'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.interBold.copyWith(
                                        color: theme.textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),
                const SizedBox(),
                const Expanded(
                  flex: 9,
                  child: CrmToDoBoard(),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
    verticalButtonsPc: Column(
      spacing: 10,
      children: [
        if (selectedBoardId != null)
          EmmaUiAnchorTarget(
            anchorKey: 'tms.todo.pc.automation_button',
            child: SizedBox(
              height: 48,
              width: 48,
              child: ElevatedButton(
                style: elevatedButtonStyleRounded10.copyWith(
                  backgroundColor: WidgetStatePropertyAll(
                    theme.dashboardContainer,
                  ),
                ),
                onPressed: () => openTmsBoardAutomationStudio(
                  theme,
                  context,
                  boardId: selectedBoardId.toString(),
                  boardName: (currentBoard?.name ?? 'TMS Board').toString(),
                ),
                child: Icon(
                  Icons.auto_awesome_motion_rounded,
                  color: theme.fillColor,
                ),
              ),
            ),
          ),
        EmmaUiAnchorTarget(
          // @emma-backend: EmmaAnchors.tmsTodoPcFilterButton
          anchorKey: 'tms.todo.pc.filter_button',
          child: SizedBox(
            height: 48,
            width: 48,
            child: ElevatedButton(
              style: elevatedButtonStyleRounded10.copyWith(
                backgroundColor: WidgetStatePropertyAll(
                  theme.dashboardContainer,
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (context) {
                    return BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: TaskFiltersDialog(
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
              child: Icon(
                Icons.filter_list_alt,
                color: theme.fillColor,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}
