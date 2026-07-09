import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:fav_board/widgets/board_details_ads_widget.dart';
import 'package:fav_board/widgets/create_board_dialog_widget.dart';
import 'package:fav_board/widgets/portal_favorites_boards_widget.dart';
import 'package:fav_board/widgets/property_type_selector_widget.dart';
import 'package:fav_board/widgets/similar_ads_widget.dart';
import 'package:fav_board/widgets/sort_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/lottie.dart';

class BoardDetailsMobileScreen extends ConsumerStatefulWidget {
  const BoardDetailsMobileScreen({super.key});

  @override
  ConsumerState<BoardDetailsMobileScreen> createState() =>
      _BoardDetailsMobileScreenState();
}

class _BoardDetailsMobileScreenState
    extends ConsumerState<BoardDetailsMobileScreen> {
  final sideMenuKey = GlobalKey<SideMenuState>();

  final ScrollController boardAdsScrollController = ScrollController();
  final ScrollController similarAdsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
    });
  }

  @override
  void dispose() {
    boardAdsScrollController.dispose();
    similarAdsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final similarAds = ref.watch(selectedBoardSimilarAdsProvider);
    final selectedBoard = ref.watch(selectedBoardProvider);

    AsyncValue<void>? similarLoad;
    if (selectedBoard?.id != null) {
      similarLoad = ref.watch(similarAdsForBoardProvider(selectedBoard!.id!));
    }

    final isSimilarLoading = similarLoad?.isLoading ?? false;

    final theme = ref.watch(themeColorsProvider);
    final textFieldColor = theme.textColor;
    final textColor = theme.textColor;
    final color = Theme.of(context).primaryColor;
    final isDefaultDarkSystem = ref.watch(isDefaultDarkSystemProvider);

    return Column(
      children: [
        SizedBox(height: TopAppBarSize.resolve(context)),
        Expanded(
          child: CustomScrollView(
            controller: boardAdsScrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    spacing: 20,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedBoard != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                spacing: 10,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${selectedBoard.title}',
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  Text(
                                    '${selectedBoard.advertisements?.length ?? 0} ${'properties'.tr}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: theme.textColor.withAlpha(
                                        (255 * 0.5).toInt(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              spacing: 8,
                              children: [
                                GestureDetector(
                                  onTap: () => BoardCard.showOptionsMenuFor(
                                    context,
                                    ref,
                                    selectedBoard,
                                    isMobile: true,
                                  ),
                                  child: Container(
                                    height: 40.h,
                                    width: 40.h,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: theme.dashboardContainer,
                                    ),
                                    child: Center(
                                      child: AppIcons.moreVertical(
                                        color: theme.textColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SortButtonWidget(),
                              ],
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          spacing: 8,
                          children: const [
                            SortButtonWidget(),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: BoardDetailsAds(
                  isDefaultDarkSystem: isDefaultDarkSystem,
                  color: color,
                  textColor: textColor,
                  textFieldColor: textFieldColor,
                ),
              ),

              SliverToBoxAdapter(
                child: const SizedBox(height: 24),
              ),

              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                        top: 55.h,
                        bottom: 55.h,
                        left: 10.w,
                      ),
                      height: 750.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.dashboardContainer,
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
                        isMobile: true,
                      ),
                    ),
                    Positioned(
                      bottom: 70,
                      right: 20,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: theme.adPopBackground,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            builder: (context) => const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                              child: PropertyTypeSelector(isMobile: true),
                            ),
                          );
                        },
                        child: Container(
                          height: 48.h,
                          width: 48.h,
                          decoration: BoxDecoration(
                            color: theme.themeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: AppIcons.sort(
                              color: theme.themeTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}