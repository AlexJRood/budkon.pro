import 'package:core/kernel/kernel.dart';
import 'package:core/platform/route_constant.dart';

/// Dock items contributed by the wall module.
///
/// Migrated 1:1 from the shell's hard-coded `SidebarDockRegistry.local` config
/// for `AppModule.wall` (the shell keeps the dock layout/ui; wall owns its
/// items).
List<DockContribution> wallDockItems() => [
      // center rail (desktop / tablet)
      DockContribution(
        id: 'wall-main',
        label: 'Wall',
        iconKey: 'grid',
        route: Routes.wall,
        dock: 'wall',
        section: DockSection.center,
        order: 1,
        anchorKey: 'dock.wall.item.center.wall-main',
      ),
      DockContribution(
        id: 'wall-events',
        label: 'Events',
        iconKey: 'location',
        route: Routes.wallEvents,
        dock: 'wall',
        section: DockSection.center,
        order: 2,
        anchorKey: 'dock.wall.item.center.wall-events',
      ),
      // mobile bottom bar
      DockContribution(
        id: 'wall-mobile-wall',
        label: 'Wall',
        iconKey: 'grid',
        route: Routes.wall,
        dock: 'wall',
        section: DockSection.mobileBottom,
        order: 1,
      ),
      DockContribution(
        id: 'wall-mobile-events',
        label: 'Events',
        iconKey: 'location',
        route: Routes.wallEvents,
        dock: 'wall',
        section: DockSection.mobileBottom,
        order: 2,
      ),
      DockContribution(
        id: 'wall-mobile-profile',
        label: '',
        iconKey: 'profile',
        dock: 'wall',
        section: DockSection.mobileBottom,
        order: 3,
      ),
    ];
