// =====================================================================
// lib/router_web/modules/automation_routes.dart
// =====================================================================
import 'package:automation/automation_studio.dart' deferred as automation;
import 'package:core/shell/manager/bar_manager.dart';
import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

import 'package:core/platform/route_constant.dart';

const AppModule _automationAppModule = AppModule.automation;

final Map<Pattern, BeamRouteBuilder> automationRoutes = {
  // ===================================================================
  // Automation Studio — list
  // ===================================================================

  Routes.automation: automationWorkflowListPage,
  Routes.automationWorkflows: automationWorkflowListPage,

  // ===================================================================
  // Automation Studio — create / builder / edit
  // ===================================================================

  Routes.automationCreate: automationCreatePage,
  Routes.automationBuilderPattern: automationBuilderPage,
  Routes.automationEditPattern: automationBuilderPage,

  // ===================================================================
  // Automation Studio — form builder
  // ===================================================================

  Routes.automationForm: automationFormBuilderPage,

  // ===================================================================
  // Automation Studio — history / approvals
  // ===================================================================

  Routes.automationHistory: automationHistoryPage,
  Routes.automationApprovals: automationApprovalsPage,

  // ===================================================================
  // Contextual Automation Studio routes
  // ===================================================================

  Routes.automationDashboard: automationDashboardContextPage,
  Routes.automationDashboardWidget: automationDashboardWidgetContextPage,
  Routes.automationTmsColumnPattern: automationTmsColumnContextPage,
  Routes.automationCalendarEventPattern: automationCalendarEventContextPage,
};

BeamPage automationWorkflowListPage(
  BuildContext context,
  BeamState state,
  Object? data,
) {
  final rawScopeType = _stringArg(data, state, 'scope_type');
  final companyId = _intArg(data, state, 'company_id');
  final ownerId = _intArg(data, state, 'owner_id');

  return _automationBeamPage(
    context: context,
    key: ValueKey('automation-workflows-$rawScopeType-$companyId-$ownerId'),
    child: buildDeferredScreen(
      automation.loadLibrary,
      () {
        final scopeType = _scopeTypeFromRaw(rawScopeType);
        final contextData = _contextDataFromData(data);

        return _withAutomationConfig(
          child: automation.AutomationWorkflowListScreen(
            scopeType: scopeType,
            companyId: companyId,
            ownerId: ownerId,
            contextData: contextData,
          ),
        );
      },
    ),
  );
}

BeamPage automationCreatePage(
  BuildContext context,
  BeamState state,
  Object? data,
) {
  return _automationBeamPage(
    context: context,
    key: const ValueKey('automation-create'),
    child: buildDeferredScreen(
      automation.loadLibrary,
      () {
        final contextData = _contextDataFromData(data);

        return _withAutomationConfig(
          child: automation.AutomationBuilderScreen(
            contextData: contextData,
          ),
        );
      },
    ),
  );
}

BeamPage automationBuilderPage(
  BuildContext context,
  BeamState state,
  Object? data,
) {
  final workflowId = state.pathParameters['workflowId'] ??
      _stringArg(data, state, 'workflow_id') ??
      _stringArg(data, state, 'id');

  return _automationBeamPage(
    context: context,
    key: ValueKey('automation-builder-$workflowId'),
    child: buildDeferredScreen(
      automation.loadLibrary,
      () => _withAutomationConfig(
        child: automation.AutomationBuilderScreen(
          workflowId: workflowId,
        ),
      ),
    ),
  );
}

BeamPage automationFormBuilderPage(
  BuildContext context,
  BeamState state,
  Object? data,
) {
  return _automationBeamPage(
    context: context,
    key: const ValueKey('automation-form-builder'),
    child: buildDeferredScreen(
      automation.loadLibrary,
      () {
        final contextData = _contextDataFromData(data);

        return _withAutomationConfig(
          child: automation.AutomationFormBuilderScreen(
            contextData: contextData,
          ),
        );
      },
    ),
  );
}

BeamPage automationHistoryPage(
  BuildContext context,
  BeamState state,
  Object? data,
) {
  final workflowId = _stringArg(data, state, 'workflow_id');

  return _automationBeamPage(
    context: context,
    key: ValueKey('automation-history-$workflowId'),
    child: buildDeferredScreen(
      automation.loadLibrary,
      () => _withAutomationConfig(
        child: automation.AutomationHistoryScreen(
          workflowId: workflowId,
        ),
      ),
    ),
  );
}

BeamPage automationApprovalsPage(
  BuildContext context,
  BeamState state,
  Object? data,
) {
  return _automationBeamPage(
    context: context,
    key: const ValueKey('automation-approvals'),
    child: buildDeferredScreen(
      automation.loadLibrary,
      () => _withAutomationConfig(
        child: automation.AutomationApprovalInboxScreen(),
      ),
    ),
  );
}

// =====================================================================
// Context pages
// =====================================================================

BeamPage automationDashboardContextPage(
  BuildContext context,
  BeamState state,
  Object? data,
) {
  final dashboardId = _stringArg(data, state, 'dashboard_id');
  final dashboardName = _stringArg(data, state, 'dashboard_name');
  final dashboardType = _stringArg(data, state, 'dashboard_type') ?? 'main';
  final companyId = _intArg(data, state, 'company_id');
  final userId = _intArg(data, state, 'user_id');
  final rawScopeType = _stringArg(data, state, 'scope_type');

  return _automationBeamPage(
    context: context,
    key: ValueKey('automation-dashboard-$dashboardId-$companyId-$userId'),
    child: buildDeferredScreen(
      automation.loadLibrary,
      () {
        final contextData = automation.AutomationContextData.dashboard(
          dashboardId: dashboardId,
          dashboardName: dashboardName,
          dashboardType: dashboardType,
          companyId: companyId,
          userId: userId,
          defaultScopeType: _scopeTypeFromRaw(rawScopeType),
        );

        return _withAutomationConfig(
          child: automation.AutomationWorkflowListScreen(
            scopeType: contextData.defaultScopeType,
            companyId: contextData.companyId,
            ownerId: contextData.userId,
            contextData: contextData,
          ),
        );
      },
    ),
  );
}

BeamPage automationDashboardWidgetContextPage(
  BuildContext context,
  BeamState state,
  Object? data,
) {
  final widgetType = _stringArg(data, state, 'widget_type') ?? 'unknown';
  final widgetId = _stringArg(data, state, 'widget_id');
  final widgetTitle = _stringArg(data, state, 'widget_title');
  final dashboardId = _stringArg(data, state, 'dashboard_id');
  final dashboardName = _stringArg(data, state, 'dashboard_name');
  final companyId = _intArg(data, state, 'company_id');
  final userId = _intArg(data, state, 'user_id');
  final rawScopeType = _stringArg(data, state, 'scope_type');

  return _automationBeamPage(
    context: context,
    key: ValueKey(
      'automation-dashboard-widget-$widgetType-$widgetId-$dashboardId',
    ),
    child: buildDeferredScreen(
      automation.loadLibrary,
      () {
        final contextData = automation.AutomationContextData.dashboardWidget(
          widgetType: widgetType,
          widgetId: widgetId,
          widgetTitle: widgetTitle,
          dashboardId: dashboardId,
          dashboardName: dashboardName,
          companyId: companyId,
          userId: userId,
          defaultScopeType: _scopeTypeFromRaw(rawScopeType),
        );

        return _withAutomationConfig(
          child: automation.AutomationWorkflowListScreen(
            scopeType: contextData.defaultScopeType,
            companyId: contextData.companyId,
            ownerId: contextData.userId,
            contextData: contextData,
          ),
        );
      },
    ),
  );
}

BeamPage automationTmsColumnContextPage(
  BuildContext context,
  BeamState state,
  Object? data,
) {
  final columnId = state.pathParameters['columnId'] ??
      _stringArg(data, state, 'column_id') ??
      '';

  final columnKey = _stringArg(data, state, 'column_key') ?? '';
  final columnName = _stringArg(data, state, 'column_name') ?? 'Column';
  final boardId = _stringArg(data, state, 'board_id') ?? '';
  final companyId = _intArg(data, state, 'company_id');
  final userId = _intArg(data, state, 'user_id');

  return _automationBeamPage(
    context: context,
    key: ValueKey('automation-tms-column-$columnId'),
    child: buildDeferredScreen(
      automation.loadLibrary,
      () {
        final contextData = automation.AutomationContextData.tmsColumn(
          columnId: columnId,
          columnKey: columnKey,
          columnName: columnName,
          boardId: boardId,
          companyId: companyId,
          userId: userId,
        );

        return _withAutomationConfig(
          child: automation.AutomationWorkflowListScreen(
            scopeType: contextData.defaultScopeType,
            companyId: contextData.companyId,
            ownerId: contextData.userId,
            contextData: contextData,
          ),
        );
      },
    ),
  );
}

BeamPage automationCalendarEventContextPage(
  BuildContext context,
  BeamState state,
  Object? data,
) {
  final eventId = state.pathParameters['eventId'] ??
      _stringArg(data, state, 'event_id') ??
      '';

  final eventTitle = _stringArg(data, state, 'event_title');
  final clientId = _stringArg(data, state, 'client_id');
  final companyId = _intArg(data, state, 'company_id');
  final userId = _intArg(data, state, 'user_id');

  return _automationBeamPage(
    context: context,
    key: ValueKey('automation-calendar-event-$eventId'),
    child: buildDeferredScreen(
      automation.loadLibrary,
      () {
        final contextData = automation.AutomationContextData.calendarEvent(
          eventId: eventId,
          eventTitle: eventTitle,
          clientId: clientId,
          companyId: companyId,
          userId: userId,
        );

        return _withAutomationConfig(
          child: automation.AutomationWorkflowListScreen(
            scopeType: contextData.defaultScopeType,
            companyId: contextData.companyId,
            ownerId: contextData.userId,
            contextData: contextData,
          ),
        );
      },
    ),
  );
}

// =====================================================================
// Helpers
// =====================================================================

BeamPage _automationBeamPage({
  required BuildContext context,
  required LocalKey key,
  required Widget child,
}) {
  return BeamPage(
    key: key,
    title: Routes.getWebsiteTitle(context),
    child: child,
    routeBuilder: (ctx, settings, routeChild) =>
        transparentRouteBuilder(ctx, settings, routeChild),
  );
}

/// IMPORTANT:
/// This helper references deferred automation symbols,
/// so call it only after automation.loadLibrary() has completed.
Widget _withAutomationConfig({
  required Widget child,
}) {
  return automation.AutomationStudioConfigScope(
    config: automation.AutomationStudioConfig(
      // ApiServices obsługuje realne requesty,
      // więc baseUrl jest tu tylko wymaganym polem configu.
      baseUrl: '',
      appModule: _automationAppModule,
      translate: (context, key) => key.tr,
      paddingPc: 0,
      paddingTablet: 0,
      paddingMobile: 0,
      enableScroll: false,
      isTopAppBarOff: false,
    ),
    child: child,
  );
}

Map<String, dynamic> _dataMap(Object? data) {
  if (data is Map<String, dynamic>) return data;

  if (data is Map) {
    return data.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  return const {};
}

String? _stringArg(Object? data, BeamState state, String key) {
  final map = _dataMap(data);

  final fromData = map[key];
  if (fromData != null && fromData.toString().trim().isNotEmpty) {
    return fromData.toString();
  }

  final fromQuery = state.queryParameters[key];
  if (fromQuery != null && fromQuery.trim().isNotEmpty) {
    return fromQuery;
  }

  return null;
}

int? _intArg(Object? data, BeamState state, String key) {
  final value = _stringArg(data, state, key);
  if (value == null) return null;

  return int.tryParse(value);
}

/// No return type on purpose.
/// Deferred classes/enums cannot be used in type annotations.
dynamic _scopeTypeFromRaw(String? raw) {
  switch (raw) {
    case 'company':
      return automation.AutomationScopeType.company;
    case 'user':
      return automation.AutomationScopeType.user;
    case 'system':
      return automation.AutomationScopeType.system;
    default:
      return null;
  }
}

/// No type test on purpose.
/// Deferred classes cannot be used in `is automation.SomeClass`.
dynamic _contextDataFromData(Object? data) {
  final map = _dataMap(data);

  return map['contextData'] ?? map['context_data'];
}