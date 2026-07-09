import 'package:core/kernel/kernel.dart';

import 'dock.dart';
import 'routing.dart';

/// Registration surface for the automation module.
class AutomationModule extends AppModule {
  @override
  String get id => 'automation';

  @override
  List<DockContribution> dockItems() => automationDockItems();

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => automationRoutes;
}
