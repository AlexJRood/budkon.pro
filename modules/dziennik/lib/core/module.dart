import 'package:core/kernel/kernel.dart';
import 'dock.dart';
import 'routing.dart';

class DziennikModule extends AppModule {
  @override
  String get id => 'dziennik';

  @override
  List<DockContribution> dockItems() => dziennikDockItems();

  @override
  List<RouteSpec> routes() => dziennikRoutes();

  @override
  Future<void> init() async {}
}
