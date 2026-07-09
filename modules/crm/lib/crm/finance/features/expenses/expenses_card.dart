import 'package:crm/shared/models/transaction/transaction_expenses_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

class TransactionCardExpenses extends ConsumerWidget {
  final TransactionExpensesModel transaction;
  final String tag;

  // Optional overrides (so the card can match Revenue UI even if the model lacks these fields).
  final String? invoiceNumber;
  final String? status;
  final bool isMoved;
  final bool? isPaid;
  final DateTime? paymentDate;
  final num? amountOverride;
  final String? currencyOverride;

  const TransactionCardExpenses({
    super.key,
    required this.tag,
    required this.transaction,
    this.invoiceNumber,
    this.status,
    this.isMoved = false,
    this.isPaid,
    this.paymentDate,
    this.amountOverride,
    this.currencyOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final now = DateTime.now();

    final effectiveIsPayed = isPaid ?? false;
    final effectivePaymentDate = paymentDate;

    final isOverDeadline =
        !effectiveIsPayed && (effectivePaymentDate?.isBefore(now) ?? false);

    final amount = amountOverride ?? transaction.totalAmount;
    final currency = currencyOverride ?? transaction.currency;

    final chipLabel = (status != null && status!.trim().isNotEmpty)
        ? status!.trim()
        : (transaction.clients.toString().trim().isNotEmpty
            ? transaction.clients.toString()
            : 'Expense'.tr);

    final chipTitle = (status != null && status!.trim().isNotEmpty)
        ? 'Status'
        : 'Clients'.tr;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: SizedBox(
        width: 300,
        child: Hero(
          tag: tag,
          child: Container(
            height: 150,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: effectiveIsPayed
                    ? AppColors.revenueGreen.withAlpha(150)
                    : isOverDeadline
                        ? AppColors.expensesRed.withAlpha(200)
                        : theme.dashboardBoarder,
                width: 1,
              ),
              color: isMoved ? theme.adPopBackground : theme.adPopBackground.withAlpha(125),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: avatar + name
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        transaction.contractorAvatar,
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                        cacheWidth: 60,
                        cacheHeight: 60,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (_, __, ___) =>
                            Container(width: 30, height: 30, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.name.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor.withAlpha(170),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // Subtitle (invoice number if provided, else note)
                Text(
                  (invoiceNumber != null && invoiceNumber!.trim().isNotEmpty)
                      ? invoiceNumber!.trim()
                      : (transaction.note.toString().trim().isNotEmpty
                          ? transaction.note.toString()
                          : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Amount row
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
                      '$amount $currency',
                      style: TextStyle(
                        color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                // Bottom section: divider + chip (Status/Clients)
                Column(
                  children: [
                    Divider(
                      color: theme.textColor.withAlpha(80),
                      height: 8,
                      thickness: 1,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chipTitle,
                          style: TextStyle(
                            color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              chipLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textFieldColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
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
        ),
      ),
    );
  }
}
