


import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm/shared/models/transaction/transaction_expenses_model.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class ExpensesPop extends ConsumerWidget{
  final TransactionExpensesModel expense;
  final String tag;
  const ExpensesPop({super.key, required this.tag, required this.expense});


@override
Widget build(BuildContext context, WidgetRef ref){
  final theme = ref.read(themeColorsProvider);

return PopPageManager(
    isBig: true,
    tag: tag,
  child: Expanded(
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.name ?? 'Unkown'.tr, style: TextStyle(color: theme.textColor, fontSize: 22)),
                  Text(expense.totalAmount, style: TextStyle(color: theme.textColor, fontSize: 18)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
               ],
              ),
            )
          ],
         ),
    ),
  ),
  );
}
}