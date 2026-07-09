// =====================================================================
// lib/router_web/pages/finance_view_pages.dart
// =====================================================================
import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';

import 'package:crm_agent/models/bill_model.dart';
import 'package:crm_agent/models/transaction/transaction_expenses_model.dart';
import 'package:core/platform/route_constant.dart';

import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart'; // transparentRouteBuilder + buildDeferredScreen

// ===== deferred imports (cięższe UI) =====
import 'package:crm/crm/finance/pop_details/fetcher/expenses_fetcher.dart'
    deferred as expenses_fetcher; // -> ExpensesFetcher
import 'package:crm/crm/finance/pop_details/expeses_pop.dart'
    deferred as expenses_pop;     // -> ExpensesPop
import 'package:crm/preview.dart'
    deferred as preview_page;     // -> PdfPreviewPage
import 'package:crm/crm/finance/features/pdf/detail.dart'
    deferred as detail_page;      // -> DetailPage

// zgodne z: typedef BeamRouteBuilder = dynamic Function(BuildContext, BeamState, Object?)

// ---------- Expenses view ----------
BeamPage expensesViewPage(BuildContext context, BeamState state, Object? data) {
  final id = state.pathParameters['id'] ?? '';
  final route = state.pathParameters['route'] ?? '';

  if (data == null) {
    return BeamPage(
      key: ValueKey('commonPage-$route-$id'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        expenses_fetcher.loadLibrary,
        () => expenses_fetcher.ExpensesFetcher(id: id, tag: ''),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }

  final map = (data is Map) ? data as Map : const {};
  final expense = map['expense'] as TransactionExpensesModel?;
  final tag = (map['tag'] as String?) ?? '';

  if (tag.isEmpty || expense == null) {
    return BeamPage(
      key: ValueKey('commonPage-$route-$id'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        expenses_fetcher.loadLibrary,
        () => expenses_fetcher.ExpensesFetcher(id: id, tag: tag),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }

  return BeamPage(
    key: ValueKey(Routes.articlePop),
    title: Routes.getWebsiteTitle(context),
    child: buildDeferredScreen(
      expenses_pop.loadLibrary,
      () => expenses_pop.ExpensesPop(expense: expense, tag: tag),
    ),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}

// ---------- PDF preview ----------
BeamPage pdfPreviewPage(BuildContext context, BeamState state, Object? data) {
  final map = (data is Map) ? data as Map : const {};
  final singleBillItem = map['singleBillItem'] as BillModel?;
  assert(
    singleBillItem != null,
    'pdfPreviewPage requires data["singleBillItem"] as BillModel',
  );

  return BeamPage(
    key: const ValueKey(Routes.pdfPreview),
    child: buildDeferredScreen(
      preview_page.loadLibrary,
      () => preview_page.PdfPreviewPage(bill: singleBillItem!),
    ),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}

// ---------- Detail page ----------
BeamPage detailPage(BuildContext context, BeamState state, Object? data) {
  final map = (data is Map) ? data as Map : const {};
  final singleBillItem = map['singleBillItem'] as BillModel?;
  assert(
    singleBillItem != null,
    'detailPage requires data["singleBillItem"] as BillModel',
  );

  return BeamPage(
    key: const ValueKey(Routes.detail),
    child: buildDeferredScreen(
      detail_page.loadLibrary,
      () => detail_page.DetailPage(singleBillItem: singleBillItem!),
    ),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}

// ---------- Revenue view (aktualnie taki sam przepływ jak expenses) ----------
BeamPage revenueViewPage(BuildContext context, BeamState state, Object? data) {
  final id = state.pathParameters['id'] ?? '';
  final route = state.pathParameters['route'] ?? '';

  if (data == null) {
    return BeamPage(
      key: ValueKey('commonPage-$route-$id'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        expenses_fetcher.loadLibrary, // jeśli masz osobny RevenueFetcher, podmień tutaj
        () => expenses_fetcher.ExpensesFetcher(id: id, tag: ''),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }

  final map = (data is Map) ? data as Map : const {};
  final expense = map['expense'] as TransactionExpensesModel?;
  final tag = (map['tag'] as String?) ?? '';

  if (tag.isEmpty || expense == null) {
    return BeamPage(
      key: ValueKey('commonPage-$route-$id'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        expenses_fetcher.loadLibrary, // jw. podmień na revenue fetcher jeśli istnieje
        () => expenses_fetcher.ExpensesFetcher(id: id, tag: tag),
      ),
      routeBuilder: (ctx, settings, child) =>
          transparentRouteBuilder(ctx, settings, child),
    );
  }

  return BeamPage(
    key: ValueKey(Routes.articlePop),
    title: Routes.getWebsiteTitle(context),
    child: buildDeferredScreen(
      expenses_pop.loadLibrary, // jw. podmień na RevenuePop jeśli masz
      () => expenses_pop.ExpensesPop(expense: expense, tag: tag),
    ),
    routeBuilder: (ctx, settings, child) =>
        transparentRouteBuilder(ctx, settings, child),
  );
}
