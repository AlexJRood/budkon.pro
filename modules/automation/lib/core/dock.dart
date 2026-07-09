import 'package:core/kernel/kernel.dart';
import 'package:core/platform/route_constant.dart';

/// Dock items contributed by the automation module (migrated 1:1 from the
/// shell's `SidebarDockRegistry.local` config for `AppModule.automation`).
List<DockContribution> automationDockItems() => [
      // center rail
      DockContribution(
        id: 'automation-workflows',
        label: 'Workflows',
        iconKey: 'grid',
        route: Routes.automationWorkflows,
        dock: 'automation',
        section: DockSection.center,
        order: 1,
        anchorKey: 'dock.automation.item.center.workflows',
      ),
      DockContribution(
        id: 'automation-create',
        label: 'Create',
        iconKey: 'add',
        route: Routes.automationCreate,
        dock: 'automation',
        section: DockSection.center,
        order: 2,
        anchorKey: 'dock.automation.item.center.create',
      ),
      DockContribution(
        id: 'automation-form',
        label: 'Form Builder',
        iconKey: 'document',
        route: Routes.automationForm,
        dock: 'automation',
        section: DockSection.center,
        order: 3,
        anchorKey: 'dock.automation.item.center.form',
      ),
      DockContribution(
        id: 'automation-history',
        label: 'History',
        iconKey: 'viewList',
        route: Routes.automationHistory,
        dock: 'automation',
        section: DockSection.center,
        order: 4,
        anchorKey: 'dock.automation.item.center.history',
      ),
      DockContribution(
        id: 'automation-approvals',
        label: 'Approvals',
        iconKey: 'task',
        route: Routes.automationApprovals,
        dock: 'automation',
        section: DockSection.center,
        order: 5,
        anchorKey: 'dock.automation.item.center.approvals',
      ),
      // bottom
      DockContribution(
        id: 'automation-settings',
        label: 'Settings',
        iconKey: 'settings',
        route: Routes.automationWorkflows,
        dock: 'automation',
        section: DockSection.bottom,
        order: 100,
        anchorKey: 'dock.automation.item.bottom.settings',
      ),
    ];
