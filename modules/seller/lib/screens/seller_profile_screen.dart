import 'dart:math' as math;

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:seller/screens/seller_profile_pc.dart';
import 'package:seller/screens/seller_profile_mobile.dart';
import 'package:core/theme/apptheme.dart';

final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

class SellerProfileScreen extends ConsumerWidget {
  final int sellerId;
  
  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = [
      'All Advertisements',
    ];
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
    final sideMenuKey = GlobalKey<SideMenuState>();
    final selectedTab = ref.watch(selectedTabIndexProvider);
    final theme = ref.watch(themeColorsProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      enableScrool: true,
      childrenPc: [
        SellerProfilePc(
          sellerId: sellerId,
          theme: theme,
          tabs: tabs,
          grid: grid,
          selectedTab: selectedTab,
        ),
      ],
      childrenMobile: [
        SizedBox(
          height: TopAppBarSize.resolve(context),
        ),
        SellerProfileMobile(
          sellerId: sellerId,
          theme: theme,
          tabs: tabs,
          grid: grid,
          selectedTab: selectedTab,
        ),
        SizedBox(
          height: TopAppBarSize.withTopAppBar(context),
        ),
      ],
    );
  }
}

class SellerTabsScreen extends ConsumerWidget {
  final ThemeColors theme;
  final List<String> tabs;
  const SellerTabsScreen({super.key, required this.theme, required this.tabs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabIndexProvider);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(tabs.length, (index) {
            final isSelected = selectedTab == index;
            return InkWell(
              onTap:
                  () => ref
                      .read(selectedTabIndexProvider.notifier)
                      .update((_) => index),
              borderRadius: BorderRadius.circular(6.r),
              splashColor: theme.textColor.withAlpha(26),
              hoverColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: 24.w),
                padding: EdgeInsets.symmetric(vertical: 6.h),
                decoration: BoxDecoration(
                  border:
                      isSelected
                          ? const Border(
                            bottom: BorderSide(
                              color: Colors.cyanAccent,
                              width: 2.0,
                            ),
                          )
                          : null,
                ),
                child: Text(
                  tabs[index],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color:
                        isSelected
                            ? theme.textColor
                            : theme.textColor.withAlpha(128),
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
