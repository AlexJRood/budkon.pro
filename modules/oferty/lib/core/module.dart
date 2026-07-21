import 'package:core/kernel/kernel.dart';
import 'dock.dart';
import 'routing.dart';

class OfertyModule extends AppModule {
  @override
  String get id => 'oferty';

  @override
  List<DockContribution> dockItems() => ofertyDockItems();

  @override
  List<RouteSpec> routes() => ofertyRoutes();

  @override
  Future<void> init(ModuleScope scope) async {}
}

