// ignore_for_file: use_build_context_synchronously, prefer_const_constructors_in_immutables

import 'package:core/shell/manager/bar_manager.dart';
import 'package:flutter/material.dart';

import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reports/reports/landing_page_report/screens/landing_page_report_mobile.dart';
import 'package:reports/reports/landing_page_report/screens/langing_page_report_pc.dart';
import 'package:reports/reports/all_report_page/provider/all_report_provider.dart';
import 'package:reports/reports/all_report_page/screens/all_reports_screen_mobile.dart';
import 'package:reports/reports/all_report_page/screens/all_reports_screen_pc.dart';
import 'package:core/theme/lottie.dart';
import 'dart:developer';
// Provider to check if any reports exist
final hasReportsProvider = FutureProvider<bool>((ref) async {
  try {
    debugPrint('Checking if reports exist...');
    final reports = await fetchReports(
      offset: 0,
      limit: 1, // Only need to check if at least one exists
      search: '',
      ordering: '-created_at',
      ref: ref,
    );
    final hasReports = reports.isNotEmpty;
    debugPrint(
      'Reports check complete: ${hasReports ? "Reports exist" : "No reports found"}',
    );
    return hasReports;
  } catch (error) {
    debugPrint('Error checking for reports: $error');
    return false; // Default to landing page on error
  }
});

class ReportsLandingPage extends ConsumerWidget {
  const ReportsLandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideMenuKey = GlobalKey<SideMenuState>();
    final hasReportsAsync = ref.watch(hasReportsProvider);

    return hasReportsAsync.when(
      data: (hasReports) {
        // Show landing page if no reports exist, otherwise show all reports screen
        if (!hasReports) {
          return BarManager(
            appModule: AppModule.portal,
            isChildExpanded: false,
            sideMenuKey: sideMenuKey,
            childPc: LandingPageReportPc(),
            childMobile: LandingPageReportMobile(),
          );
        } else {
          return BarManager(
            appModule: AppModule.portal,
            isChildExpanded: false,
            sideMenuKey: sideMenuKey,
            childPc: AllReportsScreenPc(),
            childMobile: AllReportScreenMobile(),
          );
        }
      },
      loading:
          () => BarManager(
            appModule: AppModule.portal,
            isChildExpanded: false,
            sideMenuKey: sideMenuKey,
            childPc: Center(child: AppLottie.loading(size: 200)),
            childMobile: Center(child: AppLottie.loading(size: 450)),
          ),
      error: (error, stack) {
        debugPrint('Error in hasReportsProvider: $error');
        // Default to landing page on error
        return BarManager(
          appModule: AppModule.portal,
          isChildExpanded: false,
          sideMenuKey: sideMenuKey,
          childPc: LandingPageReportPc(),
          childMobile: LandingPageReportMobile(),
        );
      },
    );
  }
}
