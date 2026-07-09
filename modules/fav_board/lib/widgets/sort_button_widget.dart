import 'package:fav_board/providers/portal_board_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/icons.dart';

import 'package:get/get_utils/get_utils.dart';

class SortButtonWidget extends ConsumerWidget {
  const SortButtonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return PopupMenuButton<String>(
      onSelected: (value) {
        ref.read(selectedSortProvider.notifier).state = value;
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: theme.textFieldColor,
      itemBuilder: (context) {
        final selected = ref.watch(selectedSortProvider);
        return <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: Container(
              width: 198.w,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                'Sort by'.tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
          ...[
            {'value': 'price_low_to_high', 'label': 'Price: Low to High'.tr},
            {'value': 'price_high_to_low', 'label': 'Price: High to Low'.tr},
          ].map((item) {
            return PopupMenuItem<String>(
              value: item['value']!,
              padding: EdgeInsets.zero,
              child: Container(
                width: 200.w,
                padding:  EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['label']!,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (selected == item['value'])
                       Icon(Icons.check, color: theme.textColor, size: 18.sp),
                  ],
                ),
              ),
            );
          }),
        ];
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.textColor),
        ),
        child: Center(
          child:
            AppIcons.sort(color: theme.textColor),
        ),
      ),
    );
  }
}