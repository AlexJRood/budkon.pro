// ignore_for_file: use_build_context_synchronously, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:budkon_flutter/const/backgroundgradient.dart';
import 'package:budkon_flutter/const/route_constant.dart';
import 'package:core/theme/design.dart';
import 'package:budkon_flutter/widgets/crm/appbar_crm.dart';
import 'package:budkon_flutter/widgets/network_monitoring/component.dart';
import 'package:budkon_flutter/widgets/side_menu/side_menu_manager.dart';
import 'package:budkon_flutter/widgets/sidebar/sidebar_network_monitoring.dart';
// Zaimportuj provider historii nawigacji
import 'package:pie_menu/pie_menu.dart';

import 'package:budkon_flutter/widgets/side_menu/slide_rotate_menu.dart';

class HomeMonitoringPcPage extends ConsumerWidget {
  const HomeMonitoringPcPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // double screenWidth = MediaQuery.of(context).size.width;
    // // double screenHeight = MediaQuery.of(context).size.height;
    // double smallBoxWidth = screenWidth * 0.20;
    // double smallBoxHeight = smallBoxWidth *1.5;
    // double bigBoxHeight = smallBoxHeight *1.25;
    // double bigBoxWidth = smallBoxWidth *1.25;
    // double spaceBoxWidth = math.max(screenWidth * 0.023, 10);
    final sideMenuKey = GlobalKey<SideMenuState>();

    return PieCanvas(
      theme: const PieTheme(
        rightClickShowsMenu: true,
        leftClickShowsMenu: false,
        buttonTheme: PieButtonTheme(
          backgroundColor: AppColors.themeColor,
          iconColor: Colors.white,
        ),
        buttonThemeHovered: PieButtonTheme(
          backgroundColor: Color.fromARGB(96, 58, 58, 58),
          iconColor: Colors.white,
        ),
      ),
      child: Scaffold(
        body: SideMenuManager.sideMenuSettings(
          menuKey: sideMenuKey,
          child: Container(
            decoration: BoxDecoration(
                gradient: CustomBackgroundGradients.getMainMenuBackground(
                    context, ref)),
            child: Row(
              children: [
                SidebarNetworkMonitoring(
                  sideMenuKey: sideMenuKey,
                ),
                Expanded(
                  child: Column(
                    children: [
                      const TopAppBarCRM(
                        routeName: Routes.homeNetworkMonitoring,
                      ),
                      Expanded(child: NMRecentlyViewedAds()),
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Value the property'.tr,
                                  style: AppTextStyles.interMedium14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
