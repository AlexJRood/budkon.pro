// // Copy this file to your CRM app, for example:
// // lib/dynamic_dashboard/widgets/automation_studio_dashboard_widget_spec.dart
// //
// // Then add AutomationStudioDashboardWidgetSpec() to dashboardWidgetRegistryProvider.
// // Adjust the imports below if your dashboard registry/models live elsewhere.

// import 'package:automation_studio/automation_studio.dart';
// import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// // Import the file where DashboardWidgetSpec is declared.
// // In your pasted file DashboardWidgetSpec lives in the same registry file, so you can either:
// // 1) move DashboardWidgetSpec to its own shared file, or
// // 2) paste this class into the current registry file directly.
// // import 'package:crm/dynamic_dashboard/widgets/dashboard_widget_registry.dart';

// class AutomationStudioDashboardWidgetSpec extends DashboardWidgetSpec {
//   const AutomationStudioDashboardWidgetSpec();

//   @override
//   String get type => 'automation_studio';

//   @override
//   String get title => 'Automation Studio';

//   @override
//   IconData get icon => Icons.auto_awesome_motion_rounded;

//   @override
//   bool get allowMultiple => true;

//   @override
//   bool get hasSettings => true;

//   @override
//   DashboardGridSize defaultSize(DashboardBreakpoint breakpoint) {
//     switch (breakpoint) {
//       case DashboardBreakpoint.desktop:
//         return const DashboardGridSize(w: 4, h: 4);
//       case DashboardBreakpoint.tablet:
//         return const DashboardGridSize(w: 4, h: 4);
//       case DashboardBreakpoint.mobile:
//         return const DashboardGridSize(w: 4, h: 4);
//     }
//   }

//   @override
//   DashboardWidgetConstraints get constraints => const DashboardWidgetConstraints(
//         minW: 2,
//         maxW: 12,
//         minH: 2,
//         maxH: 10,
//       );

//   @override
//   Widget build(
//     BuildContext context,
//     WidgetRef ref,
//     DashboardWidgetInstance instance,
//     DashboardBreakpoint breakpoint,
//     bool isEditMode,
//   ) {
//     return AutomationStudioDashboardWidget(
//       isMobile: breakpoint == DashboardBreakpoint.mobile,
//       isEditMode: isEditMode,
//       settings: instance.settings,
//       contextData: AutomationContextData.dashboardWidget(
//         widgetType: instance.type,
//         widgetId: instance.id,
//         widgetTitle: instance.titleOverride ?? title,
//         companyId: _settingsInt(instance.settings, 'companyId'),
//         userId: _settingsInt(instance.settings, 'ownerId') ?? _settingsInt(instance.settings, 'userId'),
//         dashboardId: instance.settings['dashboardId']?.toString(),
//         dashboardName: instance.settings['dashboardName']?.toString(),
//         settings: instance.settings,
//       ),
//     );
//   }

//   @override
//   Widget buildSettingsPanel(
//     BuildContext context,
//     WidgetRef ref,
//     DashboardWidgetInstance instance,
//     ValueChanged<Map<String, dynamic>> onSettingsChanged,
//   ) {
//     return AutomationStudioDashboardSettingsPanel(
//       settings: instance.settings,
//       onSettingsChanged: onSettingsChanged,
//     );
//   }
// }

// int? _settingsInt(Map<String, dynamic> settings, String key) {
//   final value = settings[key];
//   if (value is num) return value.toInt();
//   if (value is String) return int.tryParse(value);
//   return null;
// }
