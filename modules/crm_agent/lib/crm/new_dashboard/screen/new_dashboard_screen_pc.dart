import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:crm_agent/crm/new_dashboard/widget/dashboard_last_mount_view_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_calendar_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_favorite_ad_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_recent_leads_and_chart_widget.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';

class NewDashboardScreenPc extends ConsumerWidget {
  const NewDashboardScreenPc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final theme = ref.read(themeColorsProvider);

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.agentCrm,
      childrenPc: [
        Text(
          'Hi, Welcome back!'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Read Estate Property Management Dashboard.'.tr,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Row(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                spacing: 20,
                children: [
                  DashboardLastMountViewWidget(),
                  DbRecentLeadsAndChartWidget(),
                  DbFavoriteAdWidget(),
                ],
              ),
            ),
            Expanded(child: DbCalendarWidget(isMobile: false,)),
          ],
        ),
      ],
    );
  }
}
