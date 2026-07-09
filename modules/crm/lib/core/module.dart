import 'package:flutter/widgets.dart';
import 'routing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/kernel/kernel.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart' show SideMenuState;

import 'package:crm/provider/events_provider.dart';
import 'package:crm/dynamic_dashboard/providers/dashboard_provider.dart';
import 'package:crm/dynamic_dashboard/widgets/widget_screenshot_queue_screen.dart';
import 'package:crm/data/finance/transaction_provider.dart';
import 'package:crm/data/finance/expenses_provider.dart';
import 'package:crm/data/components/finance_chart/provider.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:crm/crm/finance/features/revenue/revenue_provider.dart';

import '../bars/agent/bottombar_crm.dart';
import '../bars/mobile_crm_bars.dart';
import '../bars/panel/sidebar.dart';
import '../bars/top_app_bar_crm.dart';
import 'dock.dart';

/// Registration surface for the crm module. Owns the agent dashboard (`panel`)
/// and agent CRM (`agentCrm`) shell docks, plus the CRM top app bar.
class CrmModule extends AppModule {
  @override
  String get id => 'crm';

  @override
  List<DockContribution> dockItems() => crmDockItems();

  @override
  void resetSession(WidgetRef ref) {
    ref.invalidate(revenueAndExpensesProvider);
    ref.invalidate(revenueProvider);
    ref.invalidate(expensesTransactionProvider);
    ref.invalidate(clientProvider);
    ref.invalidate(recentContactsProvider);
    ref.invalidate(allCalendarEventsProvider);
    ref.invalidate(selectedDateProvider);
    ref.invalidate(focusedDayProvider);
    ref.invalidate(transactionProvider);
  }

  @override
  Map<String, SlotBuilder> widgetSlots() => {
        'topBar.pc.crm': (context, args) => TopAppBarCRM(
              isThatOnHover: (args['isThatOnHover'] as bool?) ?? false,
            ),
        'bottomBar.agentCrm': (context, args) => const BottombarCrm(),
        'sidebar.panel': (context, args) => SidebarPanel(
              sideMenuKey: args['sideMenuKey'] as GlobalKey<SideMenuState>,
            ),
        // CRM client-toggle pieces injected into the generic mobile top bar.
        'topBar.mobile.crmAddButton': (context, args) =>
            const CrmAddClientButton(),
        'topBar.mobile.crmClientList': (context, args) =>
            const CrmMobileClientList(),
        // Dock-styled variant: wrapIcon callback provided by TopBarDockRenderer.
        'topBar.dock.crmAddButton': (context, args) =>
            CrmAddClientDockButton(wrapIcon: args['wrapIcon'] as Widget Function(Widget, VoidCallback, String)),
        'page.dashboardScreenshotQueue': (context, args) =>
            const DashboardWidgetScreenshotQueueScreen(),
      };

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => crmRouteMap();
}
