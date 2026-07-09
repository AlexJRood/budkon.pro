import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/crm/finance/features/transactions/transaction_status_dialog.dart';

class StatusPopTrasaction extends ConsumerWidget {
  final AgentTransactionModel? transaction;
  final bool isFilter;
  const StatusPopTrasaction({
    super.key, this.transaction, required this.isFilter});


  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return PopPageManager(
      isNamedRoute: false,
              tag: 'StatusPopRevenue-${UniqueKey().toString()}',
            child: TransactionStatusDialog(contact: transaction, isFilter: isFilter,),
    );
  }
}
