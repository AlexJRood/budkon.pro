

// =====================================================================
// lib/router_web/modules/finance_pop_routes.dart
// =====================================================================
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

import 'finance_pop_pages.dart';
import 'package:core/platform/route_constant.dart';

final Map<Pattern, BeamRouteBuilder>  financePopRoutes = {
  // Revenue status pops
  Routes.revenueDashboardStatus: revenueStatusPop,
  Routes.revenueFinanceStatus: revenueStatusPop,
  Routes.revenueFinanceDraggableStatus: revenueStatusPop,
  Routes.revenueProPlansStatus: revenueStatusPop,

  // Expenses status pops
  Routes.expensesDashboardStatus: expensesStatusPop,
  Routes.expensesFinanceStatus: expensesStatusPop,
  Routes.expensesFinanceDraggableStatus: expensesStatusPop,
  Routes.expensesProPlansStatus: expensesStatusPop,

  // Transactions status pops
  Routes.transactionsDashboardStatus: transactionsStatusPop,
  Routes.transactionsFinanceStatus: transactionsStatusPop,
  Routes.transactionsFinanceDraggableStatus: transactionsStatusPop,
  Routes.transactionsProPlansStatus: transactionsStatusPop,
};
