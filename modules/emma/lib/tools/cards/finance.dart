// lib/emma/tools/cards/finance.dart
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';

import '../tool_type.dart';

/// AiTextRegister dla modułu finansów.
String financeToolHeader(AiToolDescriptor tool) {
  final kind = tool.financeKind ?? FinanceToolKind.unknown;

  switch (kind) {
    case FinanceToolKind.createExpense:
      return 'emma_created_expense'.tr;
    case FinanceToolKind.createRevenue:
      return 'emma_created_revenue'.tr;
    case FinanceToolKind.listExpenses:
      return 'emma_listed_expenses'.tr;
    case FinanceToolKind.listRevenues:
      return 'emma_listed_revenues'.tr;
    case FinanceToolKind.getExpense:
      return 'emma_got_expense_details'.tr;
    case FinanceToolKind.getRevenue:
      return 'emma_got_revenue_details'.tr;
    case FinanceToolKind.updateExpense:
      return 'emma_updated_expense'.tr;
    case FinanceToolKind.updateRevenue:
      return 'emma_updated_revenue'.tr;
    case FinanceToolKind.deleteExpense:
      return 'emma_deleted_expense'.tr;
    case FinanceToolKind.deleteRevenue:
      return 'emma_deleted_revenue'.tr;
    case FinanceToolKind.unknown:
    default:
      return 'emma_performed_finance_operation'.tr;
  }
}

class FinanceToolCard extends StatelessWidget {
  final AiToolDescriptor tool;
  final double maxWidth;

  const FinanceToolCard({
    super.key,
    required this.tool,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final r = tool.result;

    final amount = r['amount']?.toString();
    final currency = r['currency']?.toString() ?? 'PLN';

    final success = tool.ok && tool.status == 'success';

    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(115),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              success ? Colors.greenAccent.withAlpha(153) : Colors.redAccent,
          width: 0.7,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 18,
            color: success ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  financeToolHeader(tool),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (amount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$amount $currency',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
