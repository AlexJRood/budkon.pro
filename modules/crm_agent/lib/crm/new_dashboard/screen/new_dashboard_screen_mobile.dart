import 'package:core/shell/manager/bar_manager.dart';
import 'package:crm_agent/crm/components/transactions_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crm_agent/crm/new_dashboard/widget/dashboard_last_mount_view_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_calendar_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_earning_chart_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_favorite_ad_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_recent_leads_and_chart_widget.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

import 'package:get/get_utils/get_utils.dart';

class NewDashboardScreenMobile extends StatelessWidget {
  NewDashboardScreenMobile({super.key});

  final sideMenuKey = GlobalKey<SideMenuState>();

  @override
  Widget build(BuildContext context) {
    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      enableScrool: true,
      childMobile: Container(
        color: const Color.fromRGBO(35, 35, 35, 1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            spacing: 30,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Welcome back!'.tr,
                style: TextStyle(
                  color: const Color.fromRGBO(255, 255, 255, 1),
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Read Estate Property Management Dashboard.'.tr,
                style: TextStyle(
                  color: const Color.fromRGBO(200, 200, 200, 1),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const DashboardLastMountViewWidget(isMobile: true),
              FinancialWidget(),
              const DbCalendarWidget(),
              const DbRecentLeadsWidget(isMobile: true),
              const DbEarningChartWidget(),
              const DbFavoriteAdWidget(isMobile: true),
            ],
          ),
        ),
      ),
    );
  }
}
