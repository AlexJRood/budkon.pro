import 'package:core/kernel/kernel.dart';
import 'routing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portal/screens/feed/provider/feed_pop/fav_provider.dart';
import 'package:portal/screens/filters/filters_page.dart';
import 'package:portal/screens/pop_pages/pages/view_pop_changer_page.dart';

import '../bars/bottom_bar.dart';
import '../bars/top_app_bar_portal.dart';
import 'dock.dart';

/// Registration surface for the portal module.
class PortalModule extends AppModule {
  @override
  String get id => 'portal';

  @override
  List<DockContribution> dockItems() => portalDockItems();

  @override
  void resetSession(WidgetRef ref) {
    ref.invalidate(favAdsProvider);
  }

  @override
  Map<String, SlotBuilder> widgetSlots() => {
        'topBar.pc.portal': (context, args) => TopAppBarPortal(
              isThatOnHover: (args['isThatOnHover'] as bool?) ?? false,
            ),
        'bottomBar.portal': (context, args) => const BottomBarMobile(),
        'page.filters': (context, args) =>
            FiltersPage(tag: args['tag'] as String? ?? ''),
        'page.viewPopChanger': (context, args) => const ViewPopChangerPage(),
      };

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => portalRoutes;
}
