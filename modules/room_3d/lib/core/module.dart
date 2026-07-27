import 'package:core/kernel/kernel.dart';

import 'routing.dart';

/// Registration surface for the room_3d module ("tryb Simsów").
class Room3dModule extends AppModule {
  @override
  String get id => 'room_3d';

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => room3dRoutes;
}
