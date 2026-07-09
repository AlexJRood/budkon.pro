import 'package:core/ui/anchors/anchor_spec.dart';

class DynamicDashboardEmmaAnchors {
  static EmmaUiAnchorSpec pageRoot(String dashboardKey) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.page',
      label: 'Dynamic dashboard page',
      description:
          'Main dynamic dashboard page container for dashboard "$dashboardKey".',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.section,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.disabled,
      tags: ['dynamic_dashboard', 'page', dashboardKey],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
      },
    );
  }

  static EmmaUiAnchorSpec canvas(String dashboardKey) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.canvas',
      label: 'Dashboard canvas',
      description:
          'Main dashboard canvas containing all visible dashboard widgets.',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.section,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.disabled,
      tags: ['dynamic_dashboard', 'canvas', dashboardKey],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
      },
    );
  }

  static EmmaUiAnchorSpec tile({
    required String dashboardKey,
    required String instanceId,
    required String widgetType,
    required String title,
  }) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.tile.$instanceId',
      label: title,
      description:
          'Dashboard widget tile of type "$widgetType" on dashboard "$dashboardKey".',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.widget,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.disabled,
      tags: [
        'dynamic_dashboard',
        'tile',
        dashboardKey,
        widgetType,
        instanceId,
      ],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
        'instance_id': instanceId,
        'widget_type': widgetType,
      },
    );
  }

  static EmmaUiAnchorSpec verticalBar(String dashboardKey) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.vertical_bar',
      label: 'Dashboard vertical bar',
      description:
          'Vertical toolbar for editing and managing the dashboard layout.',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.section,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.disabled,
      tags: ['dynamic_dashboard', 'vertical_bar', dashboardKey],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
      },
    );
  }

  static EmmaUiAnchorSpec openBuilder(String dashboardKey) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.vertical_bar.open_builder',
      label: 'Open builder',
      description: 'Button used to enter or exit dashboard builder mode.',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.button,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      tags: ['dynamic_dashboard', 'vertical_bar', 'builder', dashboardKey],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
        'action': 'toggle_builder',
      },
    );
  }

  static EmmaUiAnchorSpec refresh(String dashboardKey) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.vertical_bar.refresh',
      label: 'Refresh dashboard',
      description: 'Button used to refresh dashboard data and layout.',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.button,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      tags: ['dynamic_dashboard', 'vertical_bar', 'refresh', dashboardKey],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
        'action': 'refresh_dashboard',
      },
    );
  }

  static EmmaUiAnchorSpec addWidget(String dashboardKey) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.vertical_bar.add_widget',
      label: 'Add widget',
      description: 'Button used to open dashboard widget marketplace.',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.button,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      tags: ['dynamic_dashboard', 'vertical_bar', 'add_widget', dashboardKey],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
        'opens': 'widget_marketplace',
      },
    );
  }

  static EmmaUiAnchorSpec saveLayout(String dashboardKey) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.vertical_bar.save_layout',
      label: 'Save layout',
      description: 'Button used to save current dashboard layout.',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.button,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      tags: ['dynamic_dashboard', 'vertical_bar', 'save', dashboardKey],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
        'action': 'save_layout',
      },
    );
  }

  static EmmaUiAnchorSpec resetLayout(String dashboardKey) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.vertical_bar.reset_layout',
      label: 'Reset layout',
      description: 'Button used to reset dashboard layout to default.',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.button,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      tags: ['dynamic_dashboard', 'vertical_bar', 'reset', dashboardKey],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
        'action': 'reset_layout',
      },
    );
  }

  static EmmaUiAnchorSpec preview(String dashboardKey) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.vertical_bar.preview',
      label: 'Preview dashboard',
      description: 'Button used to leave edit mode and preview final layout.',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.button,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      tags: ['dynamic_dashboard', 'vertical_bar', 'preview', dashboardKey],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
        'action': 'preview_dashboard',
      },
    );
  }

  static EmmaUiAnchorSpec marketplaceRoot({
    required String dashboardKey,
    required String zoneKey,
  }) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.marketplace.$zoneKey.root',
      label: 'Widget marketplace',
      description:
          'Marketplace sheet for browsing, installing and adding dashboard widgets.',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.section,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.disabled,
      tags: ['dynamic_dashboard', 'marketplace', dashboardKey, zoneKey],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
        'zone_key': zoneKey,
      },
    );
  }

  static EmmaUiAnchorSpec marketplaceSearch({
    required String dashboardKey,
    required String zoneKey,
  }) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.marketplace.$zoneKey.search',
      label: 'Marketplace search',
      description: 'Search input for filtering available dashboard widgets.',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.input,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      tags: ['dynamic_dashboard', 'marketplace', 'search', dashboardKey, zoneKey],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
        'zone_key': zoneKey,
      },
    );
  }

  static EmmaUiAnchorSpec marketplaceItem({
    required String dashboardKey,
    required String zoneKey,
    required String slug,
    required String title,
    required String category,
    required String source,
  }) {
    return EmmaUiAnchorSpec(
      anchorKey: 'dynamic_dashboard.$dashboardKey.marketplace.$zoneKey.item.$slug',
      label: title,
      description: 'Marketplace card for widget "$title".',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.card,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.disabled,
      tags: [
        'dynamic_dashboard',
        'marketplace',
        'item',
        dashboardKey,
        zoneKey,
        category,
        source,
      ],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
        'zone_key': zoneKey,
        'slug': slug,
        'category': category,
        'source': source,
      },
    );
  }

  static EmmaUiAnchorSpec marketplaceInstall({
    required String dashboardKey,
    required String zoneKey,
    required String slug,
    required String title,
  }) {
    return EmmaUiAnchorSpec(
      anchorKey:
          'dynamic_dashboard.$dashboardKey.marketplace.$zoneKey.item.$slug.install',
      label: 'Install $title',
      description: 'Install button for marketplace widget "$title".',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.button,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      tags: [
        'dynamic_dashboard',
        'marketplace',
        'install',
        dashboardKey,
        zoneKey,
      ],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
        'zone_key': zoneKey,
        'slug': slug,
      },
    );
  }

  static EmmaUiAnchorSpec marketplaceAdd({
    required String dashboardKey,
    required String zoneKey,
    required String slug,
    required String title,
  }) {
    return EmmaUiAnchorSpec(
      anchorKey:
          'dynamic_dashboard.$dashboardKey.marketplace.$zoneKey.item.$slug.add',
      label: 'Add $title',
      description: 'Add button for marketplace widget "$title".',
      module: 'dynamic_dashboard',
      screenKey: dashboardKey,
      routePattern: '/*',
      targetKind: EmmaUiAnchorTargetKind.button,
      runtimeMode: EmmaUiAnchorRuntimeMode.onDemand,
      tapMode: EmmaUiAnchorTapMode.onHighlightOnly,
      tags: [
        'dynamic_dashboard',
        'marketplace',
        'add',
        dashboardKey,
        zoneKey,
      ],
      meta: {
        'usage_mode': 'both',
        'dashboard_key': dashboardKey,
        'zone_key': zoneKey,
        'slug': slug,
      },
    );
  }
}