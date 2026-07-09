import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_target_type.dart';
import 'package:core/dndservice/widgets/dnd_receiver.dart';
import 'package:fav_board/models/portal_fav_board_model.dart';
import 'package:fav_board/providers/network_board_provider.dart';
import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'dart:math' as math;
import 'create_board_dialog_widget.dart';
import 'move_to_a_board_widget.dart';
import 'organize_into_a_board_widget.dart';

import 'package:get/get_utils/get_utils.dart';

class PortalFavoritesBoardsWidget extends ConsumerWidget {
  final bool isMobile;
  const PortalFavoritesBoardsWidget({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boards = ref.watch(portalBoardsProvider);
    final selectedSort = ref.watch(selectedSortProvider);

    // Sort boards based on selected sort option
    final sortedBoards = [...boards];
    sortedBoards.sort((a, b) {
      final aPrice = a.advertisements?.firstOrNull?.price ?? 0;
      final bPrice = b.advertisements?.firstOrNull?.price ?? 0;

      switch (selectedSort) {
        case 'price_low_to_high':
          return aPrice.compareTo(bPrice);
        case 'price_high_to_low':
          return bPrice.compareTo(aPrice);
        default:
          return 0;
      }
    });

    double screenWidth = MediaQuery.of(context).size.width;
    int grid;
    if (screenWidth >= 1440) {
      grid = math.max(1, (screenWidth / 500).ceil());
    } else if (screenWidth >= 1080) {
      grid = 3;
    } else if (screenWidth >= 600) {
      grid = 2;
    } else {
      grid = 1;
    }
    if (boards.isEmpty) {
      return Center(child: AppLottie.noResults(size: 450));
    }
    return GridView.builder(
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
      cacheExtent: 160,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      itemCount: boards.isEmpty ? 1 : sortedBoards.length,
      padding: const EdgeInsets.symmetric(vertical: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: grid,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final indexedBoard = sortedBoards[index];
        return DndReceiver(
          targets: const [DndTargetType.favBoard],
          showSnackbar: false,
          onDrop: (DndPayload payload) async {
            final adId = int.tryParse(payload.id);
            final boardId = indexedBoard.id;
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
            onTap: () {
              final id = indexedBoard.id;
              if (id == null) return;

              ref.read(selectedBoardIdProvider.notifier).state = id;

              ref
                  .read(navigationService)
                  .pushNamedScreen(Routes.favBoardDetailsPath(id));

              ref
                  .read(navigationHistoryProvider.notifier)
                  .addPage(Routes.favBoardDetailsPath(id));
            },
            onLongPress:
                isMobile
                    ? () => BoardCard.showOptionsMenuFor(
                  context,
                  ref,
                  indexedBoard,
                  isMobile: isMobile,
                )
                    : null,
            child: BoardCard(
              board: indexedBoard,
              isLast: index == sortedBoards.length - 1,
              isMobile: isMobile,
            ),
          ),
        );
      },
    );
  }
}

class BoardCard extends ConsumerWidget {
  final Board board;
  final bool isLast;
  final bool isBoardDetailsScreen;
  final bool isMobile;
  final bool isMoveToABoard;

  const BoardCard({
    super.key,
    required this.board,
    required this.isLast,
    this.isBoardDetailsScreen = false,
    this.isMobile = false,
    this.isMoveToABoard = false,
  });

  static void _openEditBoard(
    BuildContext context,
    Board board, {
    required bool isMobile,
  }) {
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder:
            (context) => FractionallySizedBox(
          heightFactor: 2.5 / 3, // 2/3 of screen height
          widthFactor: 1.0, // full width
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(50, 50, 50, 1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: CreateBoardDialog(
              boardUrl: 'https://hously.pro/feedview',
              isEdit: true,
              boardDetails: board,
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder:
            (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 1 / 3, // 1/3 width of screen
              heightFactor: 2 / 3, // 2/3 height of screen
              child: CreateBoardDialog(
                boardUrl: 'https://hously.pro/feedview',
                isEdit: true,
                boardDetails: board,
              ),
            ),
          ),
        ),
      );
    }
  }

  static void _shareBoard(
    BuildContext context,
    WidgetRef ref,
    Board board,
    int selectedTabIndex,
  ) {
    if (selectedTabIndex == 0) {
      ref
          .read(portalBoardsProvider.notifier)
          .portalBoardShareLink(context, '${board.id}', '${board.title}');
    } else {
      ref
          .read(networkBoardsProvider.notifier)
          .networkBoardShareLink(context, '${board.id}', '${board.title}');
    }
  }

  static void showOptionsMenuFor(
    BuildContext context,
    WidgetRef ref,
    Board board, {
    required bool isMobile,
  }) {
    final theme = ref.read(themeColorsProvider);
    final selectedTabIndex = ref.read(selectedTabProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => Container(
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: AppIcons.pencil(color: theme.textColor),
                title: Text('Edit'.tr, style: TextStyle(color: theme.textColor)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openEditBoard(context, board, isMobile: isMobile);
                },
              ),
              ListTile(
                leading: AppIcons.share(color: theme.textColor),
                title: Text(
                  'Share'.tr,
                  style: TextStyle(color: theme.textColor),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _shareBoard(context, ref, board, selectedTabIndex);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String resolveImage(int imgIndex) {
    if (board.advertisements!.isNotEmpty &&
        board.advertisements![0].advertisementImages.isNotEmpty) {
      final images = board.advertisements?[0].advertisementImages;
      final index = imgIndex % images!.length;
      return images[index]; // ✅ Directly return the full URL
    } else {
      return 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTXavA6OIIMUAj6rhhQptEuoAHRSeDcnDN_6A&s';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedBoardIdProvider);
    final isSelected = selectedId == board.id;
    final hoveredId = ref.watch(hoveredBoardIdProvider);
    final selectedMoveToBoardIds = ref.watch(selectedMoveToBoardIdsProvider);
    final isMultiSelected = selectedMoveToBoardIds.contains(board.id);
    final selectedAds = ref.watch(selectedMonitoringAdsProvider);
    final portalSelectedAds = ref.watch(selectedPortalAdsProvider);
    final selectedTabIndex = ref.watch(selectedTabProvider);
    final theme = ref.read(themeColorsProvider);

    if (isMoveToABoard) {
      return GestureDetector(
        onTap: () {
          final notifier = ref.read(selectedMoveToBoardIdsProvider.notifier);
          if (isMultiSelected) {
            notifier.state = [...notifier.state]..remove(board.id);
          } else {
            notifier.state = [...notifier.state, board.id!];
          }
        },
        child: Container(
          height: 82.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color:
            isMultiSelected
                ? const Color.fromRGBO(255, 255, 255, 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: isMultiSelected ? theme.textColor : Colors.transparent,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 80.w,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6.r),
                          bottomLeft: Radius.circular(6.r),
                        ),
                        child: Image.network(
                          resolveImage(0),
                          fit: BoxFit.cover,
                          height: double.infinity,
                          cacheWidth: 400,
                          filterQuality: FilterQuality.high,
                          errorBuilder:
                              (_, __, ___) => const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(6.r),
                              ),
                              child: Image.network(
                                resolveImage(1),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                cacheWidth: 400,
                                filterQuality: FilterQuality.high,
                                errorBuilder:
                                    (_, __, ___) =>
                                const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(6.r),
                              ),
                              child: Image.network(
                                resolveImage(2),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                cacheWidth: 400,
                                filterQuality: FilterQuality.high,
                                errorBuilder:
                                    (_, __, ___) =>
                                const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${board.title}',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isMultiSelected)
                GestureDetector(
                  onTap: () async {
                    bool isSuccess;
                    if (selectedTabIndex == 0) {
                      isSuccess = await ref
                          .read(portalBoardsProvider.notifier)
                          .addOrganizeToBoard(
                        portalSelectedAds.map((e) => e.id).toList(),
                        board.id!,
                      );
                    } else {
                      isSuccess = await ref
                          .read(networkBoardsProvider.notifier)
                          .addOrganizeToBoard(
                        selectedAds.map((e) => e.id).toList(),
                        board.id!,
                      );
                    }

                    if (!context.mounted) return;
                    final overlay = Overlay.of(context);
                    final overlayEntry = OverlayEntry(
                      builder:
                          (context) => Positioned(
                        top: 50,
                        left: 20,
                        right: 20,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: isSuccess ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isSuccess
                                  ? 'Added to board successfully'.tr
                                  : 'Failed to add to board'.tr,
                              style: TextStyle(color: theme.textColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );

                    overlay.insert(overlayEntry);

                    await Future.delayed(
                      Duration(seconds: 2),
                    ); // Show for 2 seconds
                    overlayEntry.remove();
                  },
                  child: Container(
                    height: 32.h,
                    width: 53.w,
                    decoration: BoxDecoration(
                      color: theme.textFieldColor.withAlpha(
                        (255 * 0.4).toInt(),
                      ),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Center(
                      child: Text(
                        'Save'.tr,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (isBoardDetailsScreen) {
      return GestureDetector(
        onTap: () {
          ref.read(selectedBoardIdProvider.notifier).state = board.id;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color:
            isSelected
                ? const Color.fromRGBO(255, 255, 255, 0.2)
                : const Color.fromRGBO(255, 255, 255, 0.0),
            border:
            isSelected
                ? Border.all(
              color: theme.textColor.withAlpha((255 * 0.7).toInt()),
              width: 1.2,
            )
                : null,
          ),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          child: Column(
            children: [
              SizedBox(
                height: 64.h,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                        ),
                        child: Image.network(
                          resolveImage(0),
                          fit: BoxFit.cover,
                          height: double.infinity,
                          cacheWidth: 400,
                          filterQuality: FilterQuality.high,
                          color:
                          isSelected
                              ? null
                              : theme.textFieldColor.withAlpha(
                            (255 * 0.5).toInt(),
                          ),
                          colorBlendMode: isSelected ? null : BlendMode.darken,
                          errorBuilder:
                              (_, __, ___) => const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(6),
                              ),
                              child: Image.network(
                                resolveImage(1),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                cacheWidth: 400,
                                filterQuality: FilterQuality.high,
                                color:
                                isSelected
                                    ? null
                                    : theme.textFieldColor.withAlpha(
                                  (255 * 0.5).toInt(),
                                ),
                                colorBlendMode:
                                isSelected ? null : BlendMode.darken,
                                errorBuilder:
                                    (_, __, ___) =>
                                const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(6),
                              ),
                              child: Image.network(
                                resolveImage(2),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                cacheWidth: 400,
                                filterQuality: FilterQuality.high,
                                color:
                                isSelected
                                    ? null
                                    : theme.textFieldColor.withAlpha(
                                  (255 * 0.5).toInt(),
                                ),
                                colorBlendMode:
                                isSelected ? null : BlendMode.darken,
                                errorBuilder:
                                    (_, __, ___) =>
                                const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${board.title}',
                style: TextStyle(
                  color:
                  isSelected
                      ? theme.textColor
                      : theme.textColor.withAlpha((255 * 0.6).toInt()),
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter:
          (_) => ref.read(hoveredBoardIdProvider.notifier).state = board.id,
      onExit: (_) => ref.read(hoveredBoardIdProvider.notifier).state = null,
      child: Container(
        height: 305.h,
        width: 329.w,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.05),
          borderRadius: BorderRadius.circular(6.r),
        ),
        padding: EdgeInsets.all(25),
        child: Column(
          spacing: 10.h,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6.r),
                            bottomLeft: Radius.circular(6.r),
                          ),
                          child: Image.network(
                            resolveImage(0),
                            fit: BoxFit.cover,
                            height: double.infinity,
                            cacheWidth: 400,
                            filterQuality: FilterQuality.high,
                            errorBuilder:
                                (_, __, ___) => const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      SizedBox(width: 5.h),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(6.r),
                                ),
                                child: Image.network(
                                  resolveImage(1),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  cacheWidth: 400,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder:
                                      (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(6.r),
                                ),
                                child: Image.network(
                                  resolveImage(2),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  cacheWidth: 400,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder:
                                      (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isMobile)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: GestureDetector(
                        onTap:
                            () => BoardCard.showOptionsMenuFor(
                          context,
                          ref,
                          board,
                          isMobile: isMobile,
                        ),
                        child: Container(
                          height: 32.h,
                          width: 32.h,
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
                    )
                  else if (hoveredId == board.id)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: GestureDetector(
                        onTap:
                            () => _openEditBoard(
                          context,
                          board,
                          isMobile: isMobile,
                        ),
                        child: Container(
                          height: 32.h,
                          width: 32.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: theme.dashboardContainer,
                          ),
                          child: Center(
                            child: AppIcons.pencil(color: theme.textColor),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${board.advertisements?.length} ${'properties'.tr} | ${board.formattedDate}',
                  style: TextStyle(color: theme.textColor, fontSize: 12.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${board.title}',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
