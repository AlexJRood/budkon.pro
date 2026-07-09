import 'package:crm/shared/models/revenue_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class TransactionCardRevenue extends ConsumerWidget {
  final AgentRevenueModel revenue;
  final String? activeSection;
  final bool isSeller;
  final bool isMoved;
  const TransactionCardRevenue({
    super.key,
    required this.revenue,
    this.activeSection,
    this.isSeller = true,
    this.isMoved = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    final now = DateTime.now();

    final isOverDeadline =
        !(revenue.isPaid ?? false) &&
        (revenue.paymentDate?.isBefore(now) ?? false);


    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Container(
        height: 150,
        width: 300,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: revenue.isPaid 
                  ? AppColors.revenueGreen.withAlpha(150) 
                    : isOverDeadline
                      ? theme.themeColor
                        : theme.dashboardBoarder,
            width: 1,
          ),
          color:
              isMoved
                  ? theme.adPopBackground
                  : theme.adPopBackground.withAlpha(125),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
                Text(
                  revenue.name.toString(),
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
                ),
            Text(
              '${revenue.invoiceNumber}',
              style: TextStyle(
                color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount'.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${revenue.amount} ${revenue.currency}',
                  style: TextStyle(
                    color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            

            Column(
              children: [
                Divider(color: theme.textColor.withAlpha(80), height: 10, thickness: 1,),
                const SizedBox(height: 4,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        color: theme.textColor.withAlpha(160),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.textColor.withAlpha(160),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        revenue.status.toString(),
                        style: TextStyle(
                          color: theme.textFieldColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
