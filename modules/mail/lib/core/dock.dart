import 'package:core/kernel/kernel.dart';
import 'package:core/platform/route_constant.dart';

/// Dock / side-menu item contributed by the mail module.
///
/// Mail lives in the `agentCrm` dock today (see `EmailView` -> BarManager
/// appModule). The shell maps this onto its SidebarDockItemConfig.
List<DockContribution> mailDockItems() => [
      DockContribution(
        id: 'mail',
        label: 'Mail',
        iconKey: 'email',
        route: Routes.emailView,
        dock: 'agentCrm',
        section: DockSection.center,
        order: 40,
        requiresAuth: true,
      ),
    ];
