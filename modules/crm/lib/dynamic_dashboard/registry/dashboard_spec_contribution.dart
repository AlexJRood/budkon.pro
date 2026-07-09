import 'dashboard_widget_spec.dart' show DashboardWidgetSpec;

final List<DashboardWidgetSpec> _specs = [];

void registerDashboardWidgetSpecs(List<DashboardWidgetSpec> specs) {
  _specs.addAll(specs);
}

List<DashboardWidgetSpec> get registeredDashboardWidgetSpecs =>
    List.unmodifiable(_specs);
