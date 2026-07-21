import 'package:core/kernel/kernel.dart';
import 'dock.dart';
import 'routing.dart';

class PortalKlientaModule extends AppModule {
  @override
  String get id => 'portal_klienta';

  @override
  List<DockContribution> dockItems() => portal_klientaDockItems();

  @override
  List<RouteSpec> routes() => portal_klientaRoutes();

  @override
  Future<void> init(ModuleScope scope) async {}
}

