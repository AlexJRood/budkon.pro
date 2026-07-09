
// =====================================================================
// lib/router_web/modules/finance_view_routes.dart
// =====================================================================
import 'finance_view_pages.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

final Map<Pattern, BeamRouteBuilder>  financeViewRoutes = {
  // Revenue/Expenses views
  Routes.revenueDashboard: revenueViewPage,
  Routes.revenueFinance: revenueViewPage,
  Routes.revenueFinanceDraggable: revenueViewPage,
  Routes.revenueProPlans: revenueViewPage,

  Routes.expensesDashboard: expensesViewPage,
  Routes.expensesFinance: expensesViewPage,
  Routes.expensesFinanceDraggable: expensesViewPage,
  Routes.expensesProPlans: expensesViewPage,
};
