import 'package:core/kernel/kernel.dart';

import 'dock.dart';
import 'routing.dart';

/// Registration surface for the wall module. The shell sees wall only through
/// [AppModule] (via the [ModuleRegistry]).
class WallModule extends AppModule {
  @override
  String get id => 'wall';

  @override
  List<DockContribution> dockItems() => wallDockItems();

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => wallRoutes;
}
