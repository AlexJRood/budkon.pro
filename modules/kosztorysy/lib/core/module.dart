import 'package:core/kernel/kernel.dart';
import 'dock.dart';
import 'routing.dart';

class KosztorysyModule extends AppModule {
  @override
  String get id => 'kosztorysy';

  @override
  List<DockContribution> dockItems() => kosztorysyDockItems();

  @override
  List<RouteSpec> routes() => kosztorysyRoutes();

  @override
  Future<void> init(ModuleScope scope) async {}
}

