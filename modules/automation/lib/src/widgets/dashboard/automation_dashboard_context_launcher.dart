import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';

import '../../models/automation_common.dart';
import '../../models/automation_context.dart';
import '../popup/automation_studio_popup.dart';

Future<T?> openDashboardAutomationStudio<T>(
  ThemeColors theme,
  BuildContext context, {
  String? dashboardId,
  String? dashboardName,
  String dashboardType = 'main',
  int? companyId,
  int? userId,
  AutomationScopeType? defaultScopeType,
  Map<String, dynamic> payload = const {},
}) {
  return showAutomationStudioPopup<T>(
    theme,
    context,
    contextData: AutomationContextData.dashboard(
      dashboardId: dashboardId,
      dashboardName: dashboardName,
      dashboardType: dashboardType,
      companyId: companyId,
      userId: userId,
      defaultScopeType: defaultScopeType,
      payload: payload,
    ),
  );
}

Future<T?> openDashboardWidgetAutomationStudio<T>(
  ThemeColors theme,
  BuildContext context, {
  required String widgetType,
  String? widgetId,
  String? widgetTitle,
  String? dashboardId,
  String? dashboardName,
  int? companyId,
  int? userId,
  AutomationScopeType? defaultScopeType,
  Map<String, dynamic> settings = const {},
  Map<String, dynamic> payload = const {},
}) {
  return showAutomationStudioPopup<T>(
    theme,
    context,
    contextData: AutomationContextData.dashboardWidget(
      widgetType: widgetType,
      widgetId: widgetId,
      widgetTitle: widgetTitle,
      dashboardId: dashboardId,
      dashboardName: dashboardName,
      companyId: companyId,
      userId: userId,
      defaultScopeType: defaultScopeType,
      settings: settings,
      payload: payload,
    ),
  );
}
