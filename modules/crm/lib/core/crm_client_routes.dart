
// =====================================================================
// lib/router_web/modules/crm_client_routes.dart
// =====================================================================
import 'crm_client_pages.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';


final Map<Pattern, BeamRouteBuilder>  crmClientRoutes = {
  // POP APP BAR CLIENT VIEWS
  Routes.proSingleClient: clientViewPage,
  Routes.proCalenderClient: clientViewPage,
  Routes.proDashboardClient: clientViewPage,
  Routes.proPlansClient: clientViewPage,
  Routes.proFinanceClient: clientViewPage,
  Routes.proHomeNetworkClient: clientViewPage,
  Routes.proSaveNetworkClient: clientViewPage,


  Routes.proclientPanel: clientViewPage,
  Routes.proTxClientPanel: clientViewPage,
  Routes.proTxDraftClientPanel: clientViewPage,
  Routes.proTxDashboardClientPanel: clientViewPage,


  Routes.networkMonitoringClient: clientViewPage,
  Routes.cloudClient: clientViewPage,
  Routes.clientPanel: clientViewPage,
  Routes.proTodoClient: clientViewPage,



  Routes.maliClient: clientViewPage,
  Routes.wallClient: clientViewPage,
  Routes.docsClient: clientViewPage,
  Routes.associationContact: clientViewPage,









  // Missing ones from comment - mapped to same builder
  Routes.proBoardClient: clientViewPage,
  Routes.proDraggableClient: clientViewPage,
  Routes.proProfileClient: clientViewPage,
  Routes.proFeedPortalClient: clientViewPage,
  Routes.proLoginClient: clientViewPage,
  Routes.proMapClient: clientViewPage,
  Routes.proListViewClient: clientViewPage,
  Routes.proFullViewClient: clientViewPage,
  Routes.proDraftViewClient: clientViewPage,
  Routes.proDraftTransactionClient: clientViewPage,
  Routes.associationMembersContact: clientViewPage,

  // Contact statuses/types pops
  Routes.proHomeNetworkContactStatuses: clientStatusPop,
  Routes.proSaveNetworkContactStatuses: clientStatusPop,
  Routes.networkMonitoringContactStatuses: clientStatusPop,
  Routes.proLandingPortalContactStatuses: clientStatusPop,
  Routes.proProfileContactStatuses: clientStatusPop,
  Routes.proFeedPortalContactStatuses: clientStatusPop,
  Routes.proLoginContactStatuses: clientStatusPop,
  Routes.proMapContactStatuses: clientStatusPop,
  Routes.proListViewContactStatuses: clientStatusPop,
  Routes.proFullViewContactStatuses: clientStatusPop,
  Routes.proCalendarContactStatuses: clientStatusPop,
  Routes.proTodoContactStatuses: clientStatusPop,
  Routes.proBoardContactStatuses: clientStatusPop,
  Routes.proSingleContactStatuses: clientStatusPop,
  Routes.proDashboardContactStatuses: clientStatusPop,
  Routes.proPlansContactStatuses: clientStatusPop,
  Routes.proFinanceContactStatuses: clientStatusPop,
  Routes.proDraggableContactStatuses: clientStatusPop,
  Routes.associationContactStatuses: clientStatusPop,
  Routes.associationMembersContactStatuses: clientStatusPop,

  
  Routes.contactTypeContacts: clientTypesPop,
};
