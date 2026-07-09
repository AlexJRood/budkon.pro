import 'package:core/kernel/kernel.dart';

import 'routing.dart';

/// Registration surface for the importer module.
class ImporterModule extends AppModule {
  @override
  String get id => 'importer';

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => dataImporterRoutes;
}
