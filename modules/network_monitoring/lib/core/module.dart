import 'package:core/kernel/kernel.dart';
import 'routing.dart';

import '../bars/bottom_bar.dart';
import 'dock.dart';

/// Registration surface for the network_monitoring module.
class NetworkMonitoringModule extends AppModule {
  @override
  String get id => 'network_monitoring';

  @override
  List<DockContribution> dockItems() => networkMonitoringDockItems();

  @override
  Map<String, SlotBuilder> widgetSlots() => {
        'bottomBar.networkMonitoring': (context, args) =>
            const NetworkMonitoringBottomBarMobile(),
      };

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => networkMonitoringRoutes;
}
