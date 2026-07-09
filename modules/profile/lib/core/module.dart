import 'package:core/kernel/kernel.dart';

import 'routing.dart';

/// Registration surface for the profile module.
class ProfileModule extends AppModule {
  @override
  String get id => 'profile';

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => profileRoutes;
}
