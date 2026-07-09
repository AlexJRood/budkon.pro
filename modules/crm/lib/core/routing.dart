import 'package:core/kernel/kernel.dart';

import 'crm.dart';
import 'employee_routes.dart';
import 'invoice.dart';
import 'your_agent.dart';
import 'crm_client_routes.dart';
import 'crm_add_client_form_routes.dart';
import 'finance_pop_routes.dart';
import 'finance_view_routes.dart';

/// Merged crm-cluster route map (crm + employee + invoice + your_agent +
/// client/add-client-form + finance pop/view). Contributed via CrmModule.routeMap().
Map<Pattern, BeamRouteBuilder> crmRouteMap() => {
      ...crmRoutes,
      ...employeeRoutes,
      ...invoiceGeneratorRoutes,
      ...yourAgentRoutes,
      ...crmClientRoutes,
      ...crmAddClientFormRoutes,
      ...financePopRoutes,
      ...financeViewRoutes,
    };
