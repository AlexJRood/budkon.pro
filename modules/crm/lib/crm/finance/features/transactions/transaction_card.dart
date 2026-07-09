import 'package:crm/data/finance/transaction_provider.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:crm/shared/models/transaction/transaction_status_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';

const defaultAvatarUrl = '$configUrl/media/avatars/avatar.jpg';

class TransactionCard extends ConsumerWidget {
  final AgentTransactionModel transaction;
  final String? activeSection;
  final bool isSeller;
  final bool isMoved;
  final int? selectedTransactionId;
  final bool hasDelete;
  final bool isMobile;

  const TransactionCard({
    super.key,
    this.isMobile = false,
    required this.transaction,
    this.activeSection,
    this.isSeller = true,
    this.isMoved = false,
    this.selectedTransactionId,
    required this.hasDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final isSelected = transaction.id == selectedTransactionId;

    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(6),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: Container(
          height: isMobile ? 70 : 165,
          width: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
             
              // strokeAlign: BorderSide.strokeAlignOutside,
              color: isSelected ? theme.themeColor : theme.dashboardBoarder,
              width: isSelected ? 3 : 1,
            ),
            color:
                isMoved
                    ? AppColors.backgroundgradient2
                    : theme.adPopBackground.withAlpha(125),
            // boxShadow:
            //     isSelected
            //         ? [
            //           BoxShadow(
            //             color: Colors.white.withAlpha(102),
            //             blurRadius: 20,
            //             offset: const Offset(0, 6),
            //           ),
            //         ]
            //         : [],
          ),
          child: Column(
            spacing: 4,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                
                decoration: BoxDecoration(
                  color:
                      transaction.isSeller
                          ? theme.themeColor
                          : theme.adPopBackground,
                  borderRadius: BorderRadius.circular(3),
                ),
                width: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: SizedBox(
                        width: 218,
                        child: Text(
                          transaction.name.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                transaction.isSeller
                                    ? AppColors.white
                                    : theme.textColor,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Image.network(
                        transaction.responsiblePersonData?.avatar ?? defaultAvatarUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),

              if (!isMobile) ...[
                if(transaction.city != null)...[
                  
                Padding(
                  padding: const EdgeInsets.only(right: 10.0, left: 10),
                  child: Text(
                    '${transaction.street}, ${transaction.city}',
                    style: TextStyle(
                      color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.only(right: 10.0, left: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transactions Type'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        transaction.isSeller ? 'Sell'.tr : 'Buy'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.only(right: 10.0, left: 10),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       Text(
                //         'Transaction amount'.tr,
                //         style: TextStyle(
                //           color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                //           fontSize: 13,
                //           fontWeight: FontWeight.w700,
                //         ),
                //       ),
                //       Text(
                //         '${transaction.amount} ${transaction.currency}',
                //         style: TextStyle(
                //           color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                //           fontSize: 13,
                //           fontWeight: FontWeight.w700,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
              Padding(
                padding: const EdgeInsets.only(right: 10.0, left: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commission'.tr,
                      style: TextStyle(
                        color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if(transaction.isCommisssionPercentage)...[
                      
                    Text(
                      '${transaction.commission} %',
                      style: TextStyle(
                        color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    ]else ...[
                                            
                    Text(
                      '${transaction.commission} ${transaction.currency}',
                      style: TextStyle(
                        color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ],
                  ],
                ),
              ),


              if (!isMobile) ...[
                
                Column(
                  children: [
                    Divider(color: theme.textColor.withAlpha(80), height: 1, thickness: 1,),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status'.tr,
                        style: TextStyle(
                          color: theme.textColor.withAlpha((255 * 0.6).toInt()),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // ⬇️ tu wstawiamy dropdown pill
                      TransactionStatusPillDropdown(
                        transactionId: transaction.id,
                      ),
                    ],
                  ),
                ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown styled exactly like the current status "pill" (same padding, bg, radius, text).
/// Uses existing notifier.moveTransaction(tx, newStatusName, null) to change column.
/// Backend will place it at the end of the list when index is null.
///
///
class TransactionStatusPillDropdown extends ConsumerWidget {
  final int transactionId;
  final bool isTransaprent;

  const TransactionStatusPillDropdown({
    super.key,
    required this.transactionId,
    this.isTransaprent = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final state = ref.watch(transactionProvider);

    return state.when(
      data: (data) {
        final List<TransactionStatus> statuses = data.statuses;
        final AgentTransactionModel? tx = data.transactions.firstWhereOrNull(
          (t) => t.id == transactionId,
        );
        if (tx == null || statuses.isEmpty) {
          return _pillContainer(
            theme: theme,
            child: Text(
              tx?.status?.toString() ?? '-',
              style: TextStyle(
                color: theme.textFieldColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        // current column by membership in transactionIndex
        final currentStatus = statuses.firstWhereOrNull(
          (s) => s.transactionIndex.contains(transactionId),
        );

        // We render a DropdownButton but hide underline & icon; keep pill visuals
        return DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.adPopBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButton<int?>(
              // keep compact look
              isDense: true,
              borderRadius: BorderRadius.circular(6),
              dropdownColor: theme.adPopBackground, // menu bg to match app
              value: currentStatus?.id,
              icon: const SizedBox.shrink(), // no trailing icon to match pill
              style: TextStyle(
                color: theme.dashboardContainer,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                overflow: TextOverflow.ellipsis,
              ),
              items:
                  statuses
                      .map(
                        (s) => DropdownMenuItem<int?>(
                          value: s.id,
                          child: Text(
                            s.statusName,
                            style: TextStyle(
                              color: theme.textColor, // text color in menu
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              // show current text inside the pill
              selectedItemBuilder:
                  (_) =>
                      statuses
                          .map(
                            (s) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                s.statusName,
                                style: TextStyle(
                                  color: theme.textColor, // same as pill text
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          )
                          .toList(),
              onChanged: (int? selectedId) {
                if (selectedId == null) return;
                final newStatus = statuses.firstWhereOrNull(
                  (s) => s.id == selectedId,
                );
                if (newStatus == null || newStatus.id == currentStatus?.id)
                  return;

                // Use your ready function; null index => append at end
                ref
                    .read(transactionProvider.notifier)
                    .moveTransaction(tx, newStatus.statusName, null);
              },
            ),
          ),
        );
      },
      loading:
          () => _pillContainer(
            theme: theme,
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.textFieldColor,
              ),
            ),
          ),
      error:
          (_, __) => _pillContainer(
            theme: theme,
            child: Text(
              '-',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
    );
  }

  /// Helper to mimic exact current pill visuals.
  Widget _pillContainer({required ThemeColors theme, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(3),
      ),
      child: child,
    );
  }
}
