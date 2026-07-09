// =====================================================================
// lib/router_web/pages/finance_pop_pages.dart
// =====================================================================
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart'; // transparentRouteBuilder + buildDeferredScreen

// ⬇️ deferred imports
import 'package:crm/crm/finance/features/pop/status_expenses_pop.dart'
    deferred as status_expenses_pop;
import 'package:crm/crm/finance/features/pop/status_revenue_pop.dart'
    deferred as status_revenue_pop;
import 'package:crm/crm/finance/features/pop/status_transaction_pop.dart'
    deferred as status_transaction_pop;

// zgodne z: typedef BeamRouteBuilder = dynamic Function(BuildContext, BeamState, Object?)

BeamPage revenueStatusPop(BuildContext context, BeamState state, Object? data) {
  final map = (data is Map) ? data as Map : const {};
  final isFilter = (map['isFilter'] as bool?) ?? false;

  return BeamPage(
    key: const ValueKey(Routes.statusPopRevenue),
    title: Routes.getWebsiteTitle(context),
    child: buildDeferredScreen(
      status_revenue_pop.loadLibrary,
      () => status_revenue_pop.StatusPopRevenue(isFilter: isFilter),
    ),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}

BeamPage transactionsStatusPop(BuildContext context, BeamState state, Object? data) {
  final map = (data is Map) ? data as Map : const {};
  final isFilter = (map['isFilter'] as bool?) ?? false;

  return BeamPage(
    key: ValueKey(Routes.statusPopRevenue), // <- poprawka klucza
    title: Routes.getWebsiteTitle(context),
    child: buildDeferredScreen(
      status_transaction_pop.loadLibrary,
      () => status_transaction_pop.StatusPopTrasaction(isFilter: isFilter),
    ),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}

BeamPage expensesStatusPop(BuildContext context, BeamState state, Object? data) {
  final map = (data is Map) ? data as Map : const {};
  final isFilter = (map['isFilter'] as bool?) ?? false;

  return BeamPage(
    key: const ValueKey(Routes.statusPopExpenses),
    title: Routes.getWebsiteTitle(context),
    child: buildDeferredScreen(
      status_expenses_pop.loadLibrary,
      () => status_expenses_pop.StatusPopExpenses(isFilter: isFilter),
    ),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}
