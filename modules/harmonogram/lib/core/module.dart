import 'package:core/kernel/kernel.dart';
import 'dock.dart';
import 'routing.dart';

class HarmonogramModule extends AppModule {
  @override
  String get id => 'harmonogram';

  @override
  List<DockContribution> dockItems() => harmonogramDockItems();

  @override
  List<RouteSpec> routes() => harmonogramRoutes();

  @override
  Future<void> init(ModuleScope scope) async {}
}

