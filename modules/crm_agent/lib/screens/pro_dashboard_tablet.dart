import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/crm/new_dashboard/widget/dashboard_daily_market_overview_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/dashboard_last_mount_view_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_recent_leads_and_chart_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_calendar_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_favorite_ad_widget.dart';
import 'package:crm_agent/crm/new_dashboard/widget/db_earning_chart_widget.dart';
import 'package:core/theme/apptheme.dart';

class ProDashboardTablet extends ConsumerWidget {
  final String dashboardKey;

  const ProDashboardTablet({super.key, required this.dashboardKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const DashboardDailyMarketOverviewWidget(),
          const SizedBox(height: 16),
          const DashboardLastMountViewWidget(isTablet: true),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: const DbRecentLeadsWidget(isMobile: false, height: 420),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: const DbEarningChartWidget()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: const DbCalendarWidget(isMobile: false),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.dashboardBoarder),
                    ),
                    child: const DbFavoriteAdWidget(isMobile: false),
                  ),
                ),
              ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
