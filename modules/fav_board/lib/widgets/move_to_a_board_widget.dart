import 'package:fav_board/providers/network_board_provider.dart';
import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:fav_board/widgets/portal_favorites_boards_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';
import 'create_board_dialog_widget.dart';

import 'package:get/get_utils/get_utils.dart';

final selectedBoardsProvider = StateProvider<List<String>>((ref) => []);
final selectedMoveToBoardIdsProvider = StateProvider<List<int>>((ref) => []);

class MoveToABoardWidget extends ConsumerWidget {
  const MoveToABoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTabIndex = ref.watch(selectedTabProvider);
    final theme = ref.read(themeColorsProvider);
    final boards =
        selectedTabIndex == 0
            ? ref.watch(portalBoardsProvider)
            : ref.watch(networkBoardsProvider);
    final selectedBoards = ref.watch(selectedBoardsProvider);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.fromRGBO(50, 50, 50, 1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        spacing: 20.h,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              spacing: 20.h,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: AppIcons.iosArrowLeft(color: theme.textColor),
                    ),
                    Text(
                      'Move to a board'.tr,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: AppIcons.close(color: theme.textColor),
                    ),
                  ],
                ),
                Text(
                  'All boards'.tr,
                  style: TextStyle(color: theme.textColor, fontSize: 13),
                ),
                Expanded(
                  child:
                      boards.isEmpty
                          ? Center(
                            child: Text(
                              'No boards found'.tr,
                              style: TextStyle(color: theme.textColor),
                            ),
                          )
                          : ListView.separated(
                            separatorBuilder:
                                (context, index) => SizedBox(height: 20.h),
                            shrinkWrap: true,
                            itemCount: boards.length,
                            itemBuilder: (context, index) {
                              final data = boards[index];
                              final isSelected = selectedBoards.contains(
                                data.id.toString(),
                              );

                              return GestureDetector(
                                onTap: () {
                                  final selectedList = [...selectedBoards];
                                  if (isSelected) {
                                    selectedList.remove(data.id.toString());
                                  } else {
                                    selectedList.add(data.id.toString());
                                  }
                                  ref
                                      .read(selectedBoardsProvider.notifier)
                                      .state = selectedList;
                                },
                                child: BoardCard(
                                  isMoveToABoard: true,
                                  board: data,
                                  isLast: false,
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
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
                          child: const CreateBoardDialog(),
                        ),
                      ),
                    ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcons.add(color: theme.textColor),
                Text(
                  'ADD BOARD'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
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
