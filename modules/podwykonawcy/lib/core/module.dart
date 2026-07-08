import 'package:core/kernel/kernel.dart';
import 'dock.dart';
import 'routing.dart';

class PodwykonawcyModule extends AppModule {
  @override
  String get id => 'podwykonawcy';

  @override
  List<DockContribution> dockItems() => podwykonawcyDockItems();

  @override
  List<RouteSpec> routes() => podwykonawcyRoutes();

  @override
  Future<void> init() async {}
}
