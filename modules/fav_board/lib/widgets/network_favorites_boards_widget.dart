import 'package:fav_board/providers/network_board_provider.dart';
import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:fav_board/widgets/portal_favorites_boards_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/platform/navigation_history_provider.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/loading_widgets.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:core/theme/lottie.dart';

class NetworkFavoritesBoardsWidget extends ConsumerWidget {
  final bool isMobile;
  const NetworkFavoritesBoardsWidget({super.key,this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boards = ref.watch(networkBoardsProvider);
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
      return Center(
        child: AppLottie.noResults(
            size: 450
        ),
      );
    }
    return GridView.builder(
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
      cacheExtent: 160,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      scrollDirection:Axis.vertical,
      itemCount: boards.isEmpty ? 3 : sortedBoards.length,
      padding: const EdgeInsets.symmetric(vertical: 16),
      gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: grid,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        if (boards.isEmpty) {
          if (kDebugMode) print('list is empry ${boards.length}');
          return ShimmerPlaceholder(
            width: 110.w,
            height: 110.w,
          ); // or your board placeholder
        }
        final indexedBoard = sortedBoards[index];
        return GestureDetector(
          onTap: () {
            final id = indexedBoard.id;
            if (id == null) return;

            ref.read(selectedBoardIdProvider.notifier).state = id;

            ref.read(navigationService).pushNamedScreen(Routes.favBoardDetailsPath(id));

            ref.read(navigationHistoryProvider.notifier)
                .addPage(Routes.favBoardDetailsPath(id));
          },
          child: BoardCard(
            board: indexedBoard,
            isLast: index == sortedBoards.length - 1,
            isMobile: isMobile,
          ),
        );
      },
    );
  }
}

