import 'package:core/kernel/kernel.dart';

import 'routing.dart';

/// Registration surface for the notes module.
class NotesModule extends AppModule {
  @override
  String get id => 'notes';

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => notesRoutes;
}
