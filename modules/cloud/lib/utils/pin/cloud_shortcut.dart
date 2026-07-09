import 'package:cloud/models/cloud_shortcut.dart';
import 'package:cloud/providers/providers.dart';
import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String kDefaultCloudQuickAccessKey = 'cloud_quick_access';

enum CloudShortcutPinDestination {
  cloudQuickAccess,
  dashboard;

  String get apiValue {
    switch (this) {
      case CloudShortcutPinDestination.cloudQuickAccess:
        return 'cloud_quick_access';
      case CloudShortcutPinDestination.dashboard:
        return 'dashboard';
    }
  }
}

class CloudDashboardPinTarget {
  final String id;
  final String label;
  final String dashboardKey;
  final String zoneKey;

  const CloudDashboardPinTarget({
    required this.id,
    required this.label,
    required this.dashboardKey,
    this.zoneKey = 'main',
  });
}

const List<CloudDashboardPinTarget> kDefaultCloudDashboardPinTargets = [
  CloudDashboardPinTarget(
    id: 'crm_main',
    label: 'CRM Dashboard',
    dashboardKey: 'crm_main',
  ),
  CloudDashboardPinTarget(
    id: 'agent_dashboard',
    label: 'Agent Dashboard',
    dashboardKey: 'agent_dashboard',
  ),
  CloudDashboardPinTarget(
    id: 'office_owner_dashboard',
    label: 'Office Owner Dashboard',
    dashboardKey: 'office_owner_dashboard',
  ),
  CloudDashboardPinTarget(
    id: 'client_panel_dashboard',
    label: 'Client Panel Dashboard',
    dashboardKey: 'client_panel_dashboard',
  ),
  CloudDashboardPinTarget(
    id: 'association_dashboard',
    label: 'Association Dashboard',
    dashboardKey: 'association_dashboard',
  ),
];

Future<CloudShortcut> pinCloudShortcut({
  required WidgetRef ref,
  required String resourceType,
  required String resourceId,
  required CloudShortcutPinDestination destination,
  String? dashboardKey,
  String zoneKey = 'main',
  String? label,
  String? subtitle,
}) async {
  final shortcut = await ref.read(cloudShortcutsApiProvider).pin(
        PinCloudShortcutRequest(
          resourceType: resourceType,
          resourceId: resourceId,
          destination: destination.apiValue,
          dashboardKey: destination == CloudShortcutPinDestination.dashboard
              ? dashboardKey
              : kDefaultCloudQuickAccessKey,
          zoneKey: zoneKey,
          label: label,
          subtitle: subtitle,
        ),
      );

  refreshCloudShortcuts(ref);
  return shortcut;
}

Future<DashboardWidgetInstance> pinCloudShortcutAndBuildWidget({
  required WidgetRef ref,
  required String resourceType,
  required String resourceId,
  required String dashboardKey,
  String zoneKey = 'main',
  String? label,
  String? subtitle,
}) async {
  final shortcut = await pinCloudShortcut(
    ref: ref,
    resourceType: resourceType,
    resourceId: resourceId,
    destination: CloudShortcutPinDestination.dashboard,
    dashboardKey: dashboardKey,
    zoneKey: zoneKey,
    label: label,
    subtitle: subtitle,
  );

  final widgetRaw = shortcut.dashboardWidget;

  if (widgetRaw.isNotEmpty) {
    return DashboardWidgetInstance.fromJson(widgetRaw);
  }

  return DashboardWidgetInstance(
    id: 'cloud_shortcut_${shortcut.id}',
    type: 'cloud_shortcut',
    titleOverride: shortcut.resourceName,
    settings: shortcut.toDashboardSettingsFallback(),
    zoneKey: zoneKey,
    catalogSlug: 'cloud-shortcut',
    sourceKey: 'native',
  );
}