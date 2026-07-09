import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:crm/shared/models/transaction/transaction_expenses_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/crm/finance/features/expenses/expenses_status_dialog.dart';

class StatusPopExpenses extends ConsumerWidget {
  final TransactionExpensesModel? transaction;
  final bool isFilter;
  const StatusPopExpenses({
    super.key,
    this.transaction, 
    required this.isFilter
    });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return PopPageManager(
      isNamedRoute: true,
              tag: 'StatusPopExpenses-${UniqueKey().toString()}',
              child: ExpensesStatusDialog(
                contact: transaction,
                isFilter: isFilter,
                ),
    );
  }
}
