import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';

enum InvoiceFlowMode {
  transaction,
  manual,
}

final invoiceFlowModeProvider = StateProvider<InvoiceFlowMode>(
  (ref) => InvoiceFlowMode.manual,
);

final selectedTransactionProvider = StateProvider<AgentTransactionModel?>(
  (ref) => null,
);