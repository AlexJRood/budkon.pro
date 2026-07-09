import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import '../../../widgets/sort_button_widget.dart';
import '../widgets/portal_favorites_boards_widget.dart';
import 'create_board_dialog_widget.dart';
import 'network_favorites_boards_widget.dart';

import 'package:get/get_utils/get_utils.dart';

class FavoritePropertiesBoardGridViewWidget extends ConsumerWidget {
  final bool isMobile;
  FavoritePropertiesBoardGridViewWidget({super.key, this.isMobile = false});

  final tabs = ['Boards | Portal'.tr, 'Boards | Network Monitoring'.tr];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTabIndex = ref.watch(selectedTabProvider);
    final theme = ref.read(themeColorsProvider);

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) SizedBox(height: 90),

            Text(
              'Your favorite properties'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SortButtonWidget(),
                    SizedBox(width: 12.w),
                    ///////// Feature to finish in version 2.0 ////////
                    // Container(
                    //   padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    //   decoration: BoxDecoration(
                    //     color: Colors.transparent,
                    //     borderRadius: BorderRadius.circular(6),
                    //     border: Border.all(color: theme.textColor),
                    //   ),
                    //   child: Center(
                    //     child: Text(
                    //       'Group'.tr,
                    //       style: TextStyle(
                    //         color: Color.fromRGBO(90, 90, 90, 1),
                    //         fontSize: 12,
                    //         fontWeight: FontWeight.w500,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(width: 12.w),
                    // Container(
                    //   height: 32.h,
                    //   padding: EdgeInsets.symmetric(horizontal: 8.w),
                    //   child: Center(
                    //     child: Text(
                    //       'Browse list'.tr,
                    //       style: TextStyle(
                    //         color: theme.textColor,
                    //         fontSize: 12,
                    //         fontWeight: FontWeight.w500,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    if (isMobile) {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder:
                            (context) => FractionallySizedBox(
                              heightFactor: 2.5 / 3,
                              widthFactor: 1.0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color.fromRGBO(50, 50, 50, 1),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                child: const CreateBoardDialog(),
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
                                  widthFactor: 1 / 3,
                                  heightFactor: 2 / 3,
                                  child: const CreateBoardDialog(),
                                ),
                              ),
                            ),
                      );
                    }
                  },
                  child: Container(
                    height: 48.h,
                    width: 48.h,
                    decoration: BoxDecoration(
                      color: theme.textFieldColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(child: AppIcons.add(color: theme.textColor)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  tabs.length,
                  (index) => GestureDetector(
                    onTap:
                        () =>
                            ref.read(selectedTabProvider.notifier).state =
                                index,
                    child: Padding(
                      padding: EdgeInsets.only(right: 24.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tabs[index],
                            style: TextStyle(
                              color:
                                  selectedTabIndex == index
                                      ? theme.textColor
                                      : theme.textColor.withAlpha(
                                        (255 * 0.6).toInt(),
                                      ),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 2,
                            width:
                                selectedTabIndex == index
                                    ? index == 1
                                        ? 210.w
                                        : 100.w
                                    : 0,
                            color: AppColors.redBeige,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            selectedTabIndex == 0
                ? PortalFavoritesBoardsWidget(isMobile: isMobile)
                : NetworkFavoritesBoardsWidget(isMobile: isMobile),
          ],
        ),
      ),
    );
  }
}
