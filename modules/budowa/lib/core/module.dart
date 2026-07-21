import 'package:core/kernel/kernel.dart';
import 'dock.dart';
import 'routing.dart';

class BudowaModule extends AppModule {
  @override
  String get id => 'budowa';

  @override
  List<DockContribution> dockItems() => budowaDockItems();

  @override
  List<RouteSpec> routes() => budowaRoutes();

  @override
  Future<void> init(ModuleScope scope) async {}
}

