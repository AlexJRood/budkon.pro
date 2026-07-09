import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_target_type.dart';
import 'package:core/dndservice/widgets/dnd_receiver.dart';
import 'package:fav_board/providers/network_board_provider.dart';
import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:fav_board/widgets/board_details_ads_widget.dart';
import 'package:fav_board/widgets/create_board_dialog_widget.dart';
import 'package:fav_board/widgets/portal_favorites_boards_widget.dart';
import 'package:fav_board/widgets/property_type_selector_widget.dart';
import 'package:fav_board/widgets/similar_ads_widget.dart';
import 'package:fav_board/widgets/sort_button_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/common/loading_widgets.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/lottie.dart';

class BoardDetailsPcScreen extends ConsumerStatefulWidget {
  const BoardDetailsPcScreen({super.key});

  @override
  ConsumerState<BoardDetailsPcScreen> createState() =>
      _BoardDetailsScreenState();
}

class _BoardDetailsScreenState extends ConsumerState<BoardDetailsPcScreen> {
  final ScrollController similarAdsScrollController = ScrollController();
  final ScrollController boardAdsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final selectedTabIndex = ref.read(selectedTabProvider);

      if (selectedTabIndex == 0) {
        await ref.read(portalBoardsProvider.notifier).fetchPortalBoards();

        final boards = ref.read(portalBoardsProvider);
        final selected = ref.read(selectedBoardIdProvider);

        if (boards.isNotEmpty && selected == null) {
          ref.read(selectedBoardIdProvider.notifier).state = boards.first.id;

          final firstId = boards.first.id;
          if (firstId != null) {
            await ref
                .read(portalBoardsProvider.notifier)
                .ensureSimilarForBoard(firstId);
          }
        } else if (selected != null) {
          await ref
              .read(portalBoardsProvider.notifier)
              .ensureSimilarForBoard(selected);
        }
      } else {
        await ref.read(networkBoardsProvider.notifier).fetchNetworkFavBoards();

        final boards = ref.read(networkBoardsProvider);
        final selected = ref.read(selectedBoardIdProvider);

        if (boards.isNotEmpty && selected == null) {
          ref.read(selectedBoardIdProvider.notifier).state = boards.first.id;
        }
      }
    });
  }

  @override
  void dispose() {
    similarAdsScrollController.dispose();
    boardAdsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTabIndex = ref.watch(selectedTabProvider);

    final boards = selectedTabIndex == 0
        ? ref.watch(portalBoardsProvider)
        : ref.watch(networkBoardsProvider);

    final selectedBoard = ref.watch(selectedBoardProvider);
    final similarAds = ref.watch(selectedBoardSimilarAdsProvider);

    if (kDebugMode) {
      debugPrint(
        '👉 similarAds count: ${similarAds.length} for board ${selectedBoard?.id}',
      );
    }

    AsyncValue<void>? similarLoad;
    if (selectedTabIndex == 0 && selectedBoard?.id != null) {
      similarLoad = ref.watch(similarAdsForBoardProvider(selectedBoard!.id!));
    }

    final isSimilarLoading = similarLoad?.isLoading ?? false;

    final theme = ref.watch(themeColorsProvider);
    final textFieldColor = theme.textColor;
    final textColor = theme.textColor;
    final color = Theme.of(context).primaryColor;
    final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: _buildBoardsSidebar(
              context: context,
              ref: ref,
              boards: boards,
              theme: theme,
            ),
          ),
          SizedBox(width: 40.w),
          Expanded(
            child: CustomScrollView(
              controller: boardAdsScrollController,
              slivers: [
                if (selectedBoard != null) ...[
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      context: context,
                      ref: ref,
                      selectedTabIndex: selectedTabIndex,
                      selectedBoard: selectedBoard,
                      theme: theme,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                  BoardDetailsAds(
                    isDefaultDarkSystem: isDefaultDarkSystem,
                    color: color,
                    textColor: textColor,
                    textFieldColor: textFieldColor,
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.textFieldColor,
                      ),
                      child: isSimilarLoading
                          ? Center(child: AppLottie.loading(size: 450))
                          : SimilarAdsWidget(
                        similarAds: similarAds,
                        scrollController: similarAdsScrollController,
                        isDefaultDarkSystem: isDefaultDarkSystem,
                        color: color,
                        textColor: textColor,
                        textFieldColor: textFieldColor,
                      ),
                    ),
                  ),
                ] else
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardsSidebar({
    required BuildContext context,
    required WidgetRef ref,
    required List boards,
    required dynamic theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.zero,
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 1 / 3,
                    heightFactor: 2 / 3,
                    child: const CreateBoardDialog(),
                  ),
                ),
              ),
            );
          },
          child: Row(
            children: [
              AppIcons.person(
                color: theme.textColor,
                height: 16.w,
                width: 16.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'ADD BOARD '.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: boards.isEmpty
                  ? List.generate(
                3,
                    (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerPlaceholder(
                    width: 110.w,
                    height: 110.w,
                  ),
                ),
              )
                  : boards.map<Widget>((board) {
                final index = boards.indexOf(board);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DndReceiver(
                    targets: const [DndTargetType.favBoard],
                    showSnackbar: false,
                    onDrop: (DndPayload payload) async {
                      final adId = int.tryParse(payload.id);
                      final boardId = board.id;
                      if (adId == null || boardId == null) return;

                      final tab = ref.read(selectedTabProvider);
                      if (tab == 0) {
                        await ref
                            .read(portalBoardsProvider.notifier)
                            .addOrganizeToBoard([adId], boardId);
                      } else {
                        await ref
                            .read(networkBoardsProvider.notifier)
                            .addOrganizeToBoard([adId], boardId);
                      }
                    },
                    child: GestureDetector(
                      onTap: () async {
                        ref.read(selectedBoardIdProvider.notifier).state =
                            board.id;

                        final tab = ref.read(selectedTabProvider);

                        if (tab == 0 && board.id != null) {
                          await ref
                              .read(portalBoardsProvider.notifier)
                              .ensureSimilarForBoard(board.id!);
                        }
                      },
                      child: BoardCard(
                        isBoardDetailsScreen: true,
                        board: board,
                        isLast: index == boards.length - 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required WidgetRef ref,
    required int selectedTabIndex,
    required dynamic selectedBoard,
    required dynamic theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selectedBoard.title}',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                Text(
                  '${selectedBoard.advertisements?.length ?? 0} ${'properties'.tr}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color.fromRGBO(145, 145, 145, 1),
                  ),
                ),
              ],
            ),
            Container(
              height: 48.h,
              width: 48.h,
              decoration: BoxDecoration(
                color: theme.textFieldColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: AppIcons.moreVertical(
                  color: theme.textColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 10,
              children: [
                SortButtonWidget(),
                PropertyTypeSelector(),
              ],
            ),
            GestureDetector(
              onTap: () {
                if (selectedTabIndex == 0) {
                  ref
                      .read(portalBoardsProvider.notifier)
                      .portalBoardShareLink(
                    context,
                    selectedBoard.id.toString(),
                    '${selectedBoard.title}',
                  );
                } else {
                  ref
                      .read(networkBoardsProvider.notifier)
                      .networkBoardShareLink(
                    context,
                    selectedBoard.id.toString(),
                    '${selectedBoard.title}',
                  );
                }
              },
              child: AppIcons.share(color: theme.textColor),
            ),
          ],
        ),
      ],
    );
  }
}