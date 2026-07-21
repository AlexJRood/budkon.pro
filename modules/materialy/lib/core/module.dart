import 'package:core/kernel/kernel.dart';
import 'dock.dart';
import 'routing.dart';

class MaterialyModule extends AppModule {
  @override
  String get id => 'materialy';

  @override
  List<DockContribution> dockItems() => materialyDockItems();

  @override
  List<RouteSpec> routes() => materialyRoutes();

  @override
  Future<void> init(ModuleScope scope) async {}
}

