import 'package:core/kernel/kernel.dart';

import 'routing.dart';

class PrzetargiModule extends AppModule {
  const PrzetargiModule();

  @override
  String get name => 'przetargi';

  @override
  List<RouteSpec> get routes => przetargiRoutes();
}
