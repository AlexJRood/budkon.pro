import 'package:core/kernel/kernel.dart';

import 'routing.dart';

/// Registration surface for the articles module.
class ArticlesModule extends AppModule {
  @override
  String get id => 'articles';

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => articlesRoutes;
}
