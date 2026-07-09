import 'package:flutter/widgets.dart';
import 'routing.dart';
import 'package:core/kernel/kernel.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart' show SideMenuState;

import '../bars/top_app_bar_docs.dart';
import '../bars/top_app_bar_mobile_docs.dart';

/// Registration surface for the docs module. Owns the docs top app bars, which
/// the shell resolves via the widget-slot registry (no bar_manager import).
class DocsModule extends AppModule {
  @override
  String get id => 'docs';

  @override
  Map<String, SlotBuilder> widgetSlots() => {
        'topBar.pc.docs': (context, args) => const TopAppBarDocs(),
        'topBar.mobile.docs': (context, args) => TopAppBarMobileDocs(
              sideMenuKey: args['sideMenuKey'] as GlobalKey<SideMenuState>,
            ),
      };

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => docsRoutes;
}
