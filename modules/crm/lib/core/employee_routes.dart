// =====================================================================
// lib/router_web/modules/employee_routes.dart
// =====================================================================

import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

import 'package:crm/employee_panel/employee_screen.dart'
    deferred as employee_management;

final Map<Pattern, BeamRouteBuilder> employeeRoutes = {
  Routes.employeeManagement: (context, state, data) {
    setupMetaTag(context);

    return BeamPage(
      key: const ValueKey(Routes.employeeManagement),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        employee_management.loadLibrary,
        () => employee_management.EmployeeManagementPanelScreen(),
      ),
    );
  },

  Routes.employeeManagementDetails: (context, state, data) {
    setupMetaTag(context);

    final rawEmployeeId = state.pathParameters['employeeId'];
    final employeeId = int.tryParse(rawEmployeeId ?? '');

    return BeamPage(
      key: ValueKey('${Routes.employeeManagementDetails}-$employeeId'),
      title: Routes.getWebsiteTitle(context),
      child: buildDeferredScreen(
        employee_management.loadLibrary,
        () => employee_management.EmployeeManagementPanelScreen(
          initialEmployeeId: employeeId,
        ),
      ),
    );
  },
};
