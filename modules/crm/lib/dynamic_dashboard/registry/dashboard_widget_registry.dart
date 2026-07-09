export 'dashboard_widget_spec.dart';

import 'package:crm/dynamic_dashboard/registry/dashboard_spec_contribution.dart';
import 'package:crm/dynamic_dashboard/registry/dashboard_widget_spec.dart';
import 'package:crm/dynamic_dashboard/specs/association_specs.dart';
import 'package:crm/dynamic_dashboard/specs/client_panel_specs.dart';
import 'package:crm/dynamic_dashboard/specs/crm_specs.dart';
import 'package:crm/dynamic_dashboard/specs/cross_module_specs.dart';
import 'package:crm/dynamic_dashboard/widgets/shortcuts_dashboard_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardWidgetRegistryProvider = Provider<DashboardWidgetRegistry>((ref) {
  return DashboardWidgetRegistry([
    ...crmDashboardSpecs(),
    const ShortcutsDashboardWidgetSpec(),
    ...clientPanelDashboardSpecs(),
    ...associationDashboardSpecs(),
    ...crossModuleDashboardSpecs(),
    ...registeredDashboardWidgetSpecs,
  ]);
});
