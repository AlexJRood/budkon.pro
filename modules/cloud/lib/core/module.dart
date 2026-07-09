import 'package:core/kernel/kernel.dart';

import 'routing.dart';

/// Registration surface for the cloud module.
class CloudModule extends AppModule {
  @override
  String get id => 'cloud';

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => cloudRoutes;
}
