import 'package:crm/crm/finance/features/expenses/expenses_board.dart';
import 'package:crm/crm/finance/features/revenue/revenue_board.dart';
import 'package:crm/crm/finance/features/transactions/transaction_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/ui/device_type_util.dart';

class FinanceCrmMobile extends ConsumerWidget {
  final String selectedSegment;

  const FinanceCrmMobile({
    super.key,
    required this.selectedSegment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: TopAppBarSize.resolve(context),
              bottom: BottomBarSize.resolve(context),
            ),
            child: Builder(
              builder: (context) {
                switch (selectedSegment) {
                  case '/revenue':
                    return CrmRevenueBoard(ref: ref, isMobile: true);
                  case '/expenses':
                    return CrmExpensesBoard(ref: ref, isMobile: true);
                  case '/transactions':
                  default:
                    return CrmTransactionBoard(isMobile: true, ref: ref);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
