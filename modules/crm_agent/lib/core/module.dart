import 'package:core/kernel/kernel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_agent/crm/providers/dashboard_provider.dart';
import 'package:crm/dynamic_dashboard/registry/dashboard_spec_contribution.dart';
import 'package:crm_agent/add_client_form/add_client_form_page.dart';
import 'package:crm_agent/add_client_form/add_client_form_mobile.dart';
import 'package:crm_agent/widget/pro_draft_detail_view_widget.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:crm_agent/dynamic/specs.dart';

class CrmAgentModule extends AppModule {
  @override
  String get id => 'crm_agent';

  @override
  Future<void> init(ModuleScope scope) async {
    registerDashboardWidgetSpecs(crmAgentDashboardSpecs());
  }

  @override
  void resetSession(WidgetRef ref) {
    ref.invalidate(dashboardProvider);
  }

  @override
  Map<String, SlotBuilder> widgetSlots() => {
    'crm.addClientForm': (context, args) => AddClientFormScreen(
          isClientView: args['isClientView'] as bool? ?? false,
          state: args['state'] as String?,
        ),
    'crm.addClientFormMobile': (context, args) => AddClientFormMobile(),
    'crm.transactionDetailView': (context, args) =>
        ProDraftDetailViewWidget(
          transaction: args['transaction'] as AgentTransactionModel,
          isMobile: args['isMobile'] as bool? ?? false,
        ),
    'crm.transactionDetailsEditor': (context, args) =>
        TransactionDetailsEditor(
          transaction: args['transaction'] as AgentTransactionModel?,
        ),
  };
}
