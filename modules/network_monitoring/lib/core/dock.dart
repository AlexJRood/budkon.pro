import 'package:core/kernel/kernel.dart';
import 'package:core/platform/route_constant.dart';

/// Dock items contributed by the network_monitoring module (migrated 1:1 from
/// the shell's `SidebarDockRegistry.local` config for `AppModule.networkMonitoring`).
List<DockContribution> networkMonitoringDockItems() => [
      // center rail
      DockContribution(
        id: 'nm-home',
        label: 'Home',
        iconKey: 'home',
        route: Routes.homeNetworkMonitoring,
        dock: 'networkMonitoring',
        section: DockSection.center,
        order: 1,
        anchorKey: 'dock.network_monitoring.item.center.nm-home',
      ),
      DockContribution(
        id: 'nm-save',
        label: 'Save',
        iconKey: 'star',
        route: Routes.saveNetworkMonitoring,
        dock: 'networkMonitoring',
        section: DockSection.center,
        order: 2,
        anchorKey: 'dock.network_monitoring.item.center.nm-save',
      ),
      DockContribution(
        id: 'nm-search',
        label: 'Szukaj',
        iconKey: 'search',
        route: Routes.networkMonitoring,
        dock: 'networkMonitoring',
        section: DockSection.center,
        order: 3,
        anchorKey: 'dock.network_monitoring.item.center.nm-search',
      ),
      // mobile bottom bar
      DockContribution(
        id: 'nm-mobile-home',
        label: 'Home',
        iconKey: 'home',
        route: Routes.homeNetworkMonitoring,
        dock: 'networkMonitoring',
        section: DockSection.mobileBottom,
        order: 1,
      ),
      DockContribution(
        id: 'nm-mobile-save',
        label: 'Saved',
        iconKey: 'star',
        route: Routes.saveNetworkMonitoring,
        dock: 'networkMonitoring',
        section: DockSection.mobileBottom,
        order: 2,
      ),
      DockContribution(
        id: 'nm-mobile-search',
        label: 'Szukaj',
        iconKey: 'search',
        route: Routes.networkMonitoring,
        dock: 'networkMonitoring',
        section: DockSection.mobileBottom,
        order: 3,
      ),
      DockContribution(
        id: 'nm-mobile-fav',
        label: '',
        iconKey: 'heart',
        route: Routes.nmFav,
        dock: 'networkMonitoring',
        section: DockSection.mobileBottom,
        order: 4,
        requiresAuth: true,
      ),
      DockContribution(
        id: 'nm-mobile-profile',
        label: '',
        iconKey: 'profile',
        dock: 'networkMonitoring',
        section: DockSection.mobileBottom,
        order: 5,
      ),
    ];
