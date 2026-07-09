

// =====================================================================
// lib/router_web/modules/crm_add_client_form_routes.dart
// =====================================================================
import 'crm_add_client_form_page.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/platform/routing/route_helpers_native.dart'
    if (dart.library.js_interop) 'package:core/platform/routing/route_helpers_web.dart';

final Map<Pattern, BeamRouteBuilder>  crmAddClientFormRoutes = {
  Routes.proAddClient: crmAddClientForm,
  Routes.addClientFormDashboard: crmAddClientForm,
  Routes.addClientFormFinance: crmAddClientForm,
  Routes.addClientFormCalendar: crmAddClientForm,
  Routes.addClientFormToDo: crmAddClientForm,
  Routes.addClientFormClientList: crmAddClientForm,
  Routes.addClientFormCloud: crmAddClientForm,
  Routes.addClientFormWall: crmAddClientForm,
  Routes.addClientFormEmail: crmAddClientForm,
  Routes.addClientFormFav: crmAddClientForm,
  Routes.addClientFormDraft: crmAddClientForm,
  Routes.addClientFormDocs: crmAddClientForm,
  Routes.addClientFormProfile: crmAddClientForm,

  // Missing variants
  Routes.proHomeNetworkAddClient: crmAddClientForm,
  Routes.proSaveNetworkAddClient: crmAddClientForm,
  Routes.networkMonitoringAddClient: crmAddClientForm,
  Routes.proLandingPortalAddClient: crmAddClientForm,
  Routes.proProfileAddClient: crmAddClientForm,
  Routes.proFeedPortalAddClient: crmAddClientForm,
  Routes.proLoginAddClient: crmAddClientForm,
  Routes.proMapAddClient: crmAddClientForm,
  Routes.proListViewAddClient: crmAddClientForm,
  Routes.proFullViewAddClient: crmAddClientForm,
  Routes.proBoardAddClient: crmAddClientForm,
  Routes.proSingleAddClient: crmAddClientForm,
  Routes.proPlansAddClient: crmAddClientForm,
  Routes.proDraggableAddClient: crmAddClientForm,
};
