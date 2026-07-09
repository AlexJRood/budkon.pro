import 'package:crm/invoices/form/provider/invoice_flow_provider.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_invoice_screen.dart';

Future<void> openAddInvoiceFromTransaction({
  required BuildContext context,
  required WidgetRef ref,
  required AgentTransactionModel transaction,
  bool isMobile = false,
}) async {
  ref.read(invoiceFlowModeProvider.notifier).state = InvoiceFlowMode.transaction;
  ref.read(selectedTransactionProvider.notifier).state = transaction;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 1100,
        height: 820,
        child: AddInvoiceScreen(
          isMobile: isMobile,
          isExpenses: false,
          initialClientId: null,
          initialTransaction: transaction,
        ),
      ),
    ),
  );
}