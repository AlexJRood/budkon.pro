import 'package:core/kernel/kernel.dart';
import 'package:core/platform/route_constant.dart';

/// Dock items contributed by the portal module (migrated 1:1 from the shell's
/// `SidebarDockRegistry.local` config for `AppModule.portal`).
List<DockContribution> portalDockItems() => [
      // center rail
      DockContribution(
        id: 'portal-home',
        label: 'Home',
        iconKey: 'home',
        route: Routes.entry,
        dock: 'portal',
        section: DockSection.center,
        order: 1,
        anchorKey: 'dock.portal.item.center.portal-home',
      ),
      DockContribution(
        id: 'portal-add',
        label: 'Dodaj',
        iconKey: 'add',
        route: Routes.add,
        dock: 'portal',
        section: DockSection.center,
        order: 2,
        anchorKey: 'dock.portal.item.center.portal-add',
      ),
      DockContribution(
        id: 'portal-search',
        label: 'Szukaj',
        iconKey: 'search',
        route: Routes.feedView,
        dock: 'portal',
        section: DockSection.center,
        order: 3,
        anchorKey: 'dock.portal.item.center.portal-search',
      ),
      // mobile bottom bar
      DockContribution(
        id: 'portal-mobile-home',
        label: 'Home',
        iconKey: 'home',
        route: Routes.entry,
        dock: 'portal',
        section: DockSection.mobileBottom,
        order: 1,
      ),
      DockContribution(
        id: 'portal-mobile-search',
        label: 'Szukaj',
        iconKey: 'search',
        route: Routes.feedView,
        dock: 'portal',
        section: DockSection.mobileBottom,
        order: 2,
      ),
      DockContribution(
        id: 'portal-mobile-fav',
        label: '',
        iconKey: 'heart',
        route: Routes.fav,
        dock: 'portal',
        section: DockSection.mobileBottom,
        order: 3,
        requiresAuth: true,
      ),
      DockContribution(
        id: 'portal-mobile-add',
        label: 'Dodaj',
        iconKey: 'add',
        route: Routes.add,
        dock: 'portal',
        section: DockSection.mobileBottom,
        order: 4,
      ),
      DockContribution(
        id: 'portal-mobile-profile',
        label: '',
        iconKey: 'profile',
        dock: 'portal',
        section: DockSection.mobileBottom,
        order: 5,
      ),
      // mobile TOP bar (data-driven, customizable). `layer:*` routes open
      // overlays instead of navigating. Menu + logo are fixed chrome in the
      // renderer.
      DockContribution(
        id: 'portal-top-chat',
        label: '',
        iconKey: 'chat',
        route: 'layer:chat',
        dock: 'portal',
        section: DockSection.mobileTop,
        order: 1,
        requiresAuth: true,
      ),
      DockContribution(
        id: 'portal-top-ai',
        label: '',
        iconKey: 'ai',
        route: 'layer:ai',
        dock: 'portal',
        section: DockSection.mobileTop,
        order: 2,
        requiresAuth: true,
      ),
    ];
