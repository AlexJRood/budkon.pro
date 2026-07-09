import 'package:core/kernel/kernel.dart';

import 'routing.dart';

/// Registration surface for the reports module.
class ReportsModule extends AppModule {
  @override
  String get id => 'reports';

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => reportRoutes;
}
