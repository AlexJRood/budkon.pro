import 'package:core/kernel/kernel.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/route_constant.dart';

/// Dock items contributed by the crm module.
///
/// The crm (agent/pro) product owns two shell docks — the agent dashboard
/// (`panel`) and the agent CRM rail (`agentCrm`) — migrated 1:1 from the
/// shell's `SidebarDockRegistry.local`. Other modules also contribute to
/// `agentCrm` (e.g. mail's email item).
List<DockContribution> crmDockItems() => [
      // ---- panel dock (agent dashboard) ----
      DockContribution(id: 'panel-leads', label: 'Leads', iconKey: 'viewList', route: Routes.leadsPanel, dock: 'panel', section: DockSection.center, order: 1, anchorKey: 'dock.panel.item.center.panel-leads'),
      DockContribution(id: 'panel-board', label: 'Board', iconKey: 'grid', route: Routes.leadsBoard, dock: 'panel', section: DockSection.center, order: 2, anchorKey: 'dock.panel.item.center.panel-board'),
      DockContribution(id: 'panel-trends', label: 'Trends', iconKey: 'trend', route: Routes.networkMonitorigManagment, dock: 'panel', section: DockSection.center, order: 3, anchorKey: 'dock.panel.item.center.panel-trends'),
      DockContribution(id: 'panel-calendar', label: 'Calendar', iconKey: 'calendar', route: Routes.proCalendar, dock: 'panel', section: DockSection.center, order: 4, anchorKey: 'dock.panel.item.center.panel-calendar'),
      DockContribution(id: 'panel-todo', label: 'Todo', iconKey: 'task', route: Routes.proTodo, dock: 'panel', section: DockSection.center, order: 5, anchorKey: 'dock.panel.item.center.panel-todo'),
      DockContribution(id: 'panel-email', label: 'Email', iconKey: 'email', route: Routes.emailView, dock: 'panel', section: DockSection.bottom, order: 1, anchorKey: 'dock.panel.item.bottom.panel-email'),
      DockContribution(id: 'panel-chat', label: 'Chat', iconKey: 'chat', route: Routes.chatWrapper, dock: 'panel', section: DockSection.bottom, order: 2, anchorKey: 'dock.panel.item.bottom.panel-chat'),
      DockContribution(id: 'panel-mobile-home', label: 'Dashboard', iconKey: 'home', route: Routes.leadsPanel, dock: 'panel', section: DockSection.mobileBottom, order: 1),
      DockContribution(id: 'panel-mobile-email', label: 'Email', iconKey: 'email', route: Routes.emailView, dock: 'panel', section: DockSection.mobileBottom, order: 2),
      DockContribution(id: 'panel-mobile-profile', label: 'Profile', iconKey: 'profile', dock: 'panel', section: DockSection.mobileBottom, order: 3),

      // ---- agentCrm dock (agent CRM rail) ----
      DockContribution(id: 'crm-dashboard', label: 'Dashboard', iconKey: 'home', route: Routes.proDashboard, dock: 'agentCrm', section: DockSection.center, order: 1, anchorKey: 'dock.crm.item.center.crm-dashboard'),
      DockContribution(id: 'crm-transactions', label: 'Transactions', iconKey: 'document', route: Routes.proTxDashboard, dock: 'agentCrm', section: DockSection.center, order: 2, anchorKey: 'dock.crm.item.center.crm-transactions'),
      DockContribution(id: 'crm-finance', label: 'Finanse', iconKey: 'pie', route: Routes.proFinance, dock: 'agentCrm', section: DockSection.center, order: 3, anchorKey: 'dock.crm.item.center.crm-finance'),
      DockContribution(id: 'crm-calendar', label: 'Calendar'.tr, iconKey: 'calendar', route: Routes.proCalendar, dock: 'agentCrm', section: DockSection.center, order: 4, anchorKey: 'dock.crm.item.center.crm-calendar'),
      DockContribution(id: 'crm-todo', label: 'To do', iconKey: 'task', route: Routes.proTodo, dock: 'agentCrm', section: DockSection.center, order: 5, anchorKey: 'dock.crm.item.center.crm-todo'),
      DockContribution(id: 'crm-clients', label: 'Clients', iconKey: 'viewList', route: Routes.proClients, dock: 'agentCrm', section: DockSection.center, order: 6, anchorKey: 'dock.crm.item.center.crm-clients'),
      DockContribution(id: 'crm-employee', label: 'Team', iconKey: 'person', route: Routes.employeeManagement, dock: 'agentCrm', section: DockSection.center, order: 7, anchorKey: 'dock.crm.item.center.crm-employee'),
      DockContribution(id: 'crm-phone-call', label: 'Rozmowa', iconKey: 'phone', dock: 'agentCrm', section: DockSection.center, order: 8, anchorKey: 'dock.crm.item.center.crm-phone-call'),
      DockContribution(id: 'crm-mobile-home', label: 'Dashboard', iconKey: 'home', route: Routes.proDashboard, dock: 'agentCrm', section: DockSection.mobileBottom, order: 1),
      DockContribution(id: 'crm-mobile-finance', label: 'Finanse', iconKey: 'pie', route: Routes.proDraggable, dock: 'agentCrm', section: DockSection.mobileBottom, order: 2),
      DockContribution(id: 'crm-mobile-calendar', label: 'Calendar', iconKey: 'calendar', route: Routes.proCalendar, dock: 'agentCrm', section: DockSection.mobileBottom, order: 3),
      DockContribution(id: 'crm-mobile-todo', label: 'Todo', iconKey: 'task', route: Routes.proTodo, dock: 'agentCrm', section: DockSection.mobileBottom, order: 4),
      DockContribution(id: 'crm-mobile-clients', label: 'Clients', iconKey: 'viewList', route: Routes.proClients, dock: 'agentCrm', section: DockSection.mobileBottom, order: 5),
    ];
