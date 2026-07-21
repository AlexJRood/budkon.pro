import 'package:core/kernel/kernel.dart';

import 'dock.dart';
import 'routing.dart';

class PrzetargiModule extends AppModule {
  @override
  String get id => 'przetargi';

  @override
  String get name => 'przetargi';

  @override
  List<RouteSpec> routes() => przetargiRoutes();

  @override
  List<DockContribution> dockItems() => przetargiDockItems();
}
