import 'package:core/kernel/kernel.dart';

import 'routing.dart';

/// Registration surface for the association module.
class AssociationModule extends AppModule {
  @override
  String get id => 'association';

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => associtationRoutes;
}
