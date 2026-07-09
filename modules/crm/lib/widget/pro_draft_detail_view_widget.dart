import 'package:core/kernel/kernel.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';

/// Thin proxy that delegates to crm_agent via the widget slot system.
/// Slot 'crm.transactionDetailView' is registered by CrmAgentModule.
class ProDraftDetailViewWidget extends StatelessWidget {
  final AgentTransactionModel transaction;
  final bool isMobile;

  const ProDraftDetailViewWidget({
    super.key,
    this.isMobile = false,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final builder = moduleRegistry.slot('crm.transactionDetailView');
    if (builder != null) {
      return builder(context, {'transaction': transaction, 'isMobile': isMobile});
    }
    return const SizedBox.shrink();
  }
}