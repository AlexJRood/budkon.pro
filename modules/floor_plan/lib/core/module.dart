import 'package:core/kernel/kernel.dart';

import 'routing.dart';

/// Registration surface for the floor_plan module.
class FloorPlanModule extends AppModule {
  @override
  String get id => 'floor_plan';

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => floorPlanRoutes;
}
