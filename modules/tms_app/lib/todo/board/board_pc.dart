import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:beamer/beamer.dart';
import 'package:crm/widget/create_todo_board_dialog_widget.dart';
import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'package:tms_app/todo/board/enum/board_sort_type.dart';
import 'package:tms_app/todo/board/provider/board_details_provider.dart';
import 'package:tms_app/todo/board/provider/sort_state_provider.dart';
import 'package:tms_app/todo/provider/todo_pie_menu.dart';
import 'package:core/user/user/user_provider.dart';

import 'provider/board_provider.dart';

class BoardPc extends ConsumerStatefulWidget {
  final AppModule appModule;

  const BoardPc({
    super.key,
    this.appModule = AppModule.agentCrm,
  });

  @override
  ConsumerState<BoardPc> createState() => _BoardPcState();
}

class _BoardPcState extends ConsumerState<BoardPc> {
  late final ScrollController listViewScrollController;
  late final GlobalKey<SideMenuState> sideMenuKey;

  @override
  void initState() {
    super.initState();

    listViewScrollController = ScrollController();
    sideMenuKey = GlobalKey<SideMenuState>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(boardManagementProvider.notifier).fetchBoards(ref);
    });
  }

  @override
  void dispose() {
    listViewScrollController.dispose();
    super.dispose();
  }

  void _openCreateBoardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const CreateTodoBoardDialogWidget(),
    );
  }

  Future<void> _openBoard({
    required int? boardId,
  }) async {
    if (boardId == null) return;

    ref.read(navigationService).pushNamedScreen(Routes.proTodo);
    ref.read(boardIdProvider.notifier).state = boardId;

    await ref
        .read(boardDetailsManagementProvider.notifier)
        .fetchBoardDetails(boardId.toString());
  }

  Color _pieOverlayColor(ThemeColors theme) {
    final bool uiIsDark = theme.textColor.computeLuminance() > 0.5;
    final base = uiIsDark ? Colors.black : Colors.white;
    return base.withValues(alpha: 0.70);
  }

  PopupMenuButton<BoardSortType> _buildSortMenu({
    required ThemeColors theme,
    required BoardSortType sortType,
    required void Function(BoardSortType type) onSelected,
    EdgeInsetsGeometry iconPadding = EdgeInsets.zero,
  }) {
    return PopupMenuButton<BoardSortType>(
      color: theme.adPopBackground,
      icon: Padding(
        padding: iconPadding,
        child: Row(
          children: [
            AppIcons.sort(
              height: 16.h,
              width: 16.w,
              color: theme.textColor,
            ),
            SizedBox(width: 4.w),
            Text(
              'Sort'.tr,
              style: AppTextStyles.interMedium.copyWith(
                color: theme.textColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<BoardSortType>(
          value: BoardSortType.createdDate,
          textStyle: TextStyle(color: theme.textColor),
          child: Row(
            children: [
              sortType == BoardSortType.createdDate
                  ? Icon(
                      Icons.check,
                      size: 18,
                      color: theme.textColor,
                    )
                  : const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(
                'Sort by Created Date'.tr,
                style: AppTextStyles.interMedium.copyWith(
                  color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<BoardSortType>(
          value: BoardSortType.aToZ,
          textStyle: TextStyle(color: theme.textColor),
          child: Row(
            children: [
              sortType == BoardSortType.aToZ
                  ? Icon(
                      Icons.check,
                      size: 18,
                      color: theme.textColor,
                    )
                  : const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(
                'Sort A-Z'.tr,
                style: AppTextStyles.interMedium.copyWith(
                  color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBoardCard({
    required dynamic board,
    required ThemeColors theme,
    required String? anchorKey,
    required String? backendRefCommentKey,
  }) {
    final card = Builder(
      builder: (pieContext) {
        return PieMenu(
          theme: PieTheme.of(pieContext).copyWith(
            overlayColor: _pieOverlayColor(theme),
          ),
          key: ValueKey(board.id),
          actions: buildPieMenuActionsTodo(
            pieContext,
            ref,
            board.id.toString(),
            theme,
          ),
          onPressed: () => _openBoard(boardId: board.id?.toInt()),
          child: AspectRatio(
            aspectRatio: 2,
            child: BoardCard(
              title: board.name,
              imageUrl: board.avatar,
            ),
          ),
        );
      },
    );

    if (anchorKey == null) {
      return card;
    }

    return EmmaUiAnchorTarget(
      anchorKey: anchorKey,
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardData = ref.watch(boardManagementProvider);
    final userAsync = ref.watch(userProvider);
    final theme = ref.watch(themeColorsProvider);

    final sortType = ref.watch(boardSortNotifierProvider);
    final sortNotifier = ref.read(boardSortNotifierProvider.notifier);
    final sortedBoards = sortNotifier.sortBoards(boardData.results);

    return EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.tmsBoardPcRoot
      anchorKey: 'tms.board.pc.root',
      runtimeMode: EmmaUiAnchorRuntimeMode.always,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: BarManager(
        sideMenuKey: sideMenuKey,
        appModule: widget.appModule,
        childrenPc: [
          SizedBox(height: 20.h),
          EmmaUiAnchorTarget(
            // @emma-backend: EmmaAnchors.tmsBoardPcHeader
            anchorKey: 'tms.board.pc.header',
            tapMode: EmmaUiAnchorTapMode.disabled,
            child: Container(
              height: 70.h,
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
              ),
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  EmmaUiAnchorTarget(
                    // @emma-backend: EmmaAnchors.tmsBoardPcCompanyTitle
                    anchorKey: 'tms.board.pc.company_title',
                    tapMode: EmmaUiAnchorTapMode.disabled,
                    child: Text(
                      'Company Name'.tr,
                      style: AppTextStyles.interBold.copyWith(
                        color: theme.textColor,
                        fontSize: 18.sp,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppIcons.star(
                        height: 32.h,
                        width: 32.w,
                        color: theme.textColor,
                      ),
                      const VerticalDivider(),
                      EmmaUiAnchorTarget(
                        // @emma-backend: EmmaAnchors.tmsBoardPcHeaderSortMenu
                        anchorKey: 'tms.board.pc.header_sort_menu',
                        child: _buildSortMenu(
                          theme: theme,
                          sortType: sortType,
                          onSelected: sortNotifier.setSort,
                        ),
                      ),
                      const VerticalDivider(),
                      EmmaUiAnchorTarget(
                        // @emma-backend: EmmaAnchors.tmsBoardPcHeaderAvatars
                        anchorKey: 'tms.board.pc.header_avatars',
                        tapMode: EmmaUiAnchorTapMode.disabled,
                        child: SizedBox(
                          height: 40,
                          width: 117,
                          child: OverlappingAvatars(
                            theme: theme,
                            avatarUrls: boardData.results
                                    ?.take(6)
                                    .map((e) => e.avatar ?? '')
                                    .toList() ??
                                [],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 30.h),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10.w,
              children: [
                const Expanded(child: SizedBox()),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10.h,
                      children: [
                        EmmaUiAnchorTarget(
                          // @emma-backend: EmmaAnchors.tmsBoardPcRecentlyViewedSection
                          anchorKey: 'tms.board.pc.recently_viewed_section',
                          tapMode: EmmaUiAnchorTapMode.disabled,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${"Recently viewed".tr} ',
                                style: AppTextStyles.interBold.copyWith(
                                  color: theme.textColor,
                                  fontSize: 18.sp,
                                ),
                              ),
                              Text(
                                'Lorem Ipsum Dolor sit amen',
                                style: AppTextStyles.interMedium.copyWith(
                                  color: theme.textColor.withAlpha(
                                    (255 * 0.6).toInt(),
                                  ),
                                  fontSize: 18.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        EmmaUiAnchorTarget(
                          // @emma-backend: EmmaAnchors.tmsBoardPcRecentBoardsStrip
                          anchorKey: 'tms.board.pc.recent_boards_strip',
                          tapMode: EmmaUiAnchorTapMode.disabled,
                          child: SizedBox(
                            height: 120.h,
                            child: GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                if (!listViewScrollController.hasClients) {
                                  return;
                                }

                                final target =
                                    listViewScrollController.offset -
                                        details.delta.dx;

                                final clampedTarget = target.clamp(
                                  listViewScrollController
                                      .position.minScrollExtent,
                                  listViewScrollController
                                      .position.maxScrollExtent,
                                );

                                listViewScrollController.jumpTo(
                                  clampedTarget.toDouble(),
                                );
                              },
                              child: ListView.separated(
                                controller: listViewScrollController,
                                scrollDirection: Axis.horizontal,
                                separatorBuilder: (context, index) =>
                                    SizedBox(width: 12.w),
                                itemCount: sortedBoards.length,
                                itemBuilder: (context, index) {
                                  final board = sortedBoards[index];

                                  return _buildBoardCard(
                                    board: board,
                                    theme: theme,
                                    anchorKey: index == 0
                                        ? 'tms.board.pc.first_recent_board_card'
                                        : null,
                                    backendRefCommentKey: 'recent',
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        EmmaUiAnchorTarget(
                          // @emma-backend: EmmaAnchors.tmsBoardPcAllBoardsSection
                          anchorKey: 'tms.board.pc.all_boards_section',
                          tapMode: EmmaUiAnchorTapMode.disabled,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'All boards'.tr,
                                    style: AppTextStyles.interBold.copyWith(
                                      color: theme.textColor,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  EmmaUiAnchorTarget(
                                    // @emma-backend: EmmaAnchors.tmsBoardPcAllBoardsSortMenu
                                    anchorKey:
                                        'tms.board.pc.all_boards_sort_menu',
                                    child: _buildSortMenu(
                                      theme: theme,
                                      sortType: sortType,
                                      onSelected: sortNotifier.setSort,
                                      iconPadding:
                                          const EdgeInsets.only(right: 16),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Lorem Ipsum Dolor sit amen',
                                style: AppTextStyles.interMedium.copyWith(
                                  color: theme.textColor.withAlpha(
                                    (255 * 0.6).toInt(),
                                  ),
                                  fontSize: 18.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        EmmaUiAnchorTarget(
                          // @emma-backend: EmmaAnchors.tmsBoardPcBoardsGrid
                          anchorKey: 'tms.board.pc.boards_grid',
                          tapMode: EmmaUiAnchorTapMode.disabled,
                          child: GridView.builder(
                            addAutomaticKeepAlives: false,
                            addSemanticIndexes: false,
                            cacheExtent: 160,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12.w,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2,
                            ),
                            itemCount: sortedBoards.length,
                            itemBuilder: (context, index) {
                              final board = sortedBoards[index];

                              return _buildBoardCard(
                                board: board,
                                theme: theme,
                                anchorKey: index == 0
                                    ? 'tms.board.pc.first_grid_board_card'
                                    : null,
                                backendRefCommentKey: 'grid',
                              );
                            },
                          ),
                        ),
                        EmmaUiAnchorTarget(
                          // @emma-backend: EmmaAnchors.tmsBoardPcAddBoardButton
                          anchorKey: 'tms.board.pc.add_board_button',
                          child: SizedBox(
                            width: 350.w,
                            height: 45,
                            child: ElevatedButton(
                              style: elevatedButtonStyleRounded10,
                              onPressed: () => _openCreateBoardDialog(context),
                              child: Row(
                                children: [
                                  AppIcons.add(
                                    color: theme.textColor,
                                    height: 16.sp,
                                    width: 16.sp,
                                  ),
                                  Text(
                                    'ADD BOARD'.tr,
                                    style: AppTextStyles.interBold.copyWith(
                                      color: theme.textColor,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 30.h),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 10.h,
                    children: [
                      userAsync.when(
                        data: (data) {
                          final avatarUrl = data?.avatarUrl ?? '';
                          final fullName =
                              '${data?.firstName ?? ''} ${data?.lastName ?? ''}'
                                  .trim();
                          final email = data?.email ?? '';

                          return EmmaUiAnchorTarget(
                            // @emma-backend: EmmaAnchors.tmsBoardPcProfileCard
                            anchorKey: 'tms.board.pc.profile_card',
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Column(
                                spacing: 10.h,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      final beamState = Beamer.of(context);
                                      beamState.beamToNamed(Routes.profile);
                                    },
                                    child: Container(
                                      height: 140.h,
                                      width: 140.h,
                                      decoration: BoxDecoration(
                                        color: theme.dashboardContainer,
                                        borderRadius: BorderRadius.circular(6),
                                        image: avatarUrl.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(avatarUrl),
                                                fit: BoxFit.cover,
                                                onError: (_, __) {},
                                              )
                                            : null,
                                      ),
                                      child: avatarUrl.isEmpty
                                          ? Icon(
                                              Icons.person,
                                              color: theme.textColor,
                                              size: 48,
                                            )
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    fullName.isEmpty ? 'User'.tr : fullName,
                                    style: AppTextStyles.interBold.copyWith(
                                      color: theme.textColor,
                                      fontSize: 24.sp,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    email,
                                    style: AppTextStyles.interBold.copyWith(
                                      color: theme.textColor.withAlpha(
                                        (255 * 0.6).toInt(),
                                      ),
                                      fontSize: 14.sp,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        error: (error, stackTrace) => AppLottie.error(),
                        loading: () => AppLottie.loading(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OverlappingAvatars extends StatelessWidget {
  final List<String> avatarUrls;
  final int maxVisible;
  final ThemeColors theme;

  const OverlappingAvatars({
    super.key,
    required this.avatarUrls,
    this.maxVisible = 4,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final visibleAvatars = avatarUrls
        .where((url) => url.trim().isNotEmpty)
        .take(maxVisible)
        .toList();

    final remaining = avatarUrls.length - visibleAvatars.length;
    final totalWidth = visibleAvatars.length * 20.0 + 18 * 2;

    return SizedBox(
      width: totalWidth + (remaining > 0 ? 40 : 0),
      height: 36,
      child: Stack(
        children: [
          for (int index = 0; index < visibleAvatars.length; index++)
            Positioned(
              left: index * 20.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.textFieldColor,
                  border: Border.all(
                    color: theme.textColor,
                    width: 2,
                  ),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(visibleAvatars[index]),
                    onError: (_, __) {},
                  ),
                ),
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: visibleAvatars.length * 20.0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.textFieldColor,
                child: Text(
                  '+$remaining',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BoardCard extends StatelessWidget {
  final String? title;
  final String? imageUrl;

  const BoardCard({
    super.key,
    required this.title,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final safeImageUrl = imageUrl?.trim() ?? '';
    final hasImage = safeImageUrl.isNotEmpty;

    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(8),
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(safeImageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha(102),
                  BlendMode.darken,
                ),
                onError: (_, __) {},
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? 'Untitled'.tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppIcons.homeModern(
            color: Colors.white,
            height: 16.h,
            width: 16.w,
          ),
        ],
      ),
    );
  }
}