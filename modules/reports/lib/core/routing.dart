// =====================================================================
// lib/router_web/modules/report_routes.dart
// =====================================================================
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart'; // <- buildDeferredScreen + setupMetaTag + transparentRouteBuilder
import 'package:core/platform/route_constant.dart';

// ================== DEFERRED IMPORTS ==================
import 'package:reports/reports/all_report_page/all_report_screen.dart'
    deferred as all_report_screen;
import 'package:reports/reports/create_report_page/create_report.dart'
    deferred as create_report;
import 'package:reports/reports/dashboard_report/dashboard_report_all.dart'
    deferred as dashboard_report;
import 'package:reports/reports/raporty_page.dart' deferred as raporty_page;
import 'package:reports/reports/comparison_result_report/result_report_all.dart'
    deferred as result_report;

import 'package:reports/reports/compare_report/report_comparison_fetcher.dart'
    deferred as compare_report;

import 'package:reports/reports/report_pdf_page/provider/report_pdf_fethcer.dart'
    deferred as report_pdf_fethcer;
import 'package:reports/reports/details/port_pdf_fetcher.dart'
    deferred as single_report_pdf;

// =====================================================================
// REPORT ROUTES MAP
// =====================================================================
final Map<Pattern, BeamPage Function(BuildContext, BeamState, Object?)>
    reportRoutes = {
  Routes.reports: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.reports),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        raporty_page.loadLibrary,
        () => raporty_page.ReportsLandingPage(),
      ),
    );
  },
  Routes.allReports: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.allReports),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        all_report_screen.loadLibrary,
        () => all_report_screen.AllReportScreen(),
      ),
    );
  },
  Routes.createReport: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.createReport),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        create_report.loadLibrary,
        () => create_report.CreateReportAll(),
      ),
    );
  },
  Routes.dashboardReport: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.dashboardReport),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        dashboard_report.loadLibrary,
        () => dashboard_report.DashboardReportAll(),
      ),
    );
  },
  Routes.reportResult: (context, state, data) {
    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.reportResult),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        result_report.loadLibrary,
        () => result_report.ResultReportAll(),
      ),
    );
  },
  Routes.singleReport: (context, state, data) {
    setupMetaTag(context);

    final reportId = int.tryParse(state.pathParameters['id'] ?? '');

    return BeamPage(
      key: ValueKey('report-result-${reportId ?? 'unknown'}'),
      title: Routes.getWebsiteTitle(context),
      child: reportId == null
          ? const Scaffold(body: Center(child: Text('Invalid report id')))
          : buildDeferredScreen(
              single_report_pdf.loadLibrary,
              () => single_report_pdf.SingleReportPdfFetcher(reportId: reportId),
            ),
    );
  },

  Routes.pdfSingleReport: (context, state, data) {
    final id = int.parse(state.pathParameters['id']!);

    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.pdfSingleReport),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        report_pdf_fethcer.loadLibrary,
        () => report_pdf_fethcer.ReportPdfFetcher(reportIds: [id]),
      ),
    );
  },
  Routes.pdfCompareReports: (context, state, data) {
    final id1 = int.parse(state.pathParameters['id1']!);
    final id2 = int.parse(state.pathParameters['id2']!);
    final id3Param = state.pathParameters['id3'];

    List<int> reportIds = [id1, id2];
    if (id3Param != null && id3Param.isNotEmpty && id3Param != '0') {
      reportIds.add(int.parse(id3Param));
    }

    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.pdfCompareReports),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        report_pdf_fethcer.loadLibrary,
        () => report_pdf_fethcer.ReportPdfFetcher(reportIds: reportIds),
      ),
    );
  },
  Routes.compareReports: (context, state, data) {
    final id1 = int.parse(state.pathParameters['id1']!);
    final id2 = int.parse(state.pathParameters['id2']!);
    final id3Param = state.pathParameters['id3'];

    List<int> reportIds = [id1, id2];
    if (id3Param != null && id3Param.isNotEmpty && id3Param != '0') {
      reportIds.add(int.parse(id3Param));
    }

    setupMetaTag(context);
    return BeamPage(
      key: const ValueKey(Routes.compareReports),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        compare_report.loadLibrary,
        () => compare_report.ReportComparisonFetcher(reportIds: reportIds),
      ),
    );
  },
};
