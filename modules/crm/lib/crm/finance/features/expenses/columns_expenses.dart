// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:crm/crm/finance/features/expenses/expenses_card.dart';
import 'package:crm/data/finance/remove_expenses.dart';
import 'package:crm/pie_menu/expenses_crm.dart';
import 'package:crm/invoices/form/screen/add_invoice_screen.dart';
import 'package:crm/invoices/widgets/invoice_details_view.dart';
import 'package:crm/shared/models/transaction/transaction_expenses_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:core/platform/navigation_service.dart' show navigationService;
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/models/dnd_target_type.dart';
import 'package:core/dndservice/widgets/dnd_receiver.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:core/theme/icons.dart';

import '../../components/custom_vertical_divider.dart';

class DraggableColumn extends StatelessWidget {
  final String status;
  final List<TransactionExpensesModel> transactions;
  final void Function(String) onAcceptColumn;
  final void Function(TransactionExpensesModel transaction, int newIndex)
  onReorder;
  final void Function(
    TransactionExpensesModel transaction,
    String newStatus,
    int? newIndex,
  )
  onMove;
  final WidgetRef ref;
  final void Function(TransactionExpensesModel transaction)
  onTransactionSelected;

  const DraggableColumn({
    super.key,
    required this.status,
    required this.transactions,
    required this.onAcceptColumn,
    required this.onReorder,
    required this.onMove,
    required this.ref,
    required this.onTransactionSelected,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double quarterScreenHeight = screenHeight / 4 * 3;
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final theme = ref.read(themeColorsProvider);
    final tag = '${UniqueKey().toString}';
    final screenSize = MediaQuery.of(context).size;

    // Column drag target for reordering columns
    return DndSender(
      payload: DndPayload(
        type: DndPayloadType.expensesColumnHeader,
        id: status,
        action: 'reorder_column',

        data: {'status': status},
      ),

      useLongPress: true,
      feedbackBuilder: (context) {
        return Material(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: AppColors.light50,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.dark50,
                  offset: Offset(0, 4),
                  blurRadius: 25,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 50,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    gradient: CrmGradients.adGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      status,
                      style: AppTextStyles.interMedium14.copyWith(
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
                ...transactions.map((transaction) {
                  return SizedBox(
                    width: 300,
                    child: TransactionCardExpenses(
                      transaction: transaction,
                      tag: tag,
                      key: ValueKey(transaction.id),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      child: Row(
        children: [
          // Main column drop target (for cards to drop onto the column)
          DndReceiver(
            showSnackbar: false,
            acceptColor: AppColors.light50,
            rejectColor: Colors.red,
            targets: const [DndTargetType.expensesColumn],
            showPreview: false,
            showHoverFeedback: true,
            onDrop: (payload) {
              if (payload.action == 'move_to_column') {
                final transaction =
                    payload.data!['transaction'] as TransactionExpensesModel;
                onMove(transaction, status, null);
              }
              if (payload.action == 'reorder_column') {
                final status = payload.data!['status'] as String;
                onAcceptColumn(status);
              }
            },
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    height: 50,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      status,
                      style: AppTextStyles.interMedium14.copyWith(
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...transactions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final transaction = entry.value;

                            final card = SizedBox(
                              width: 300,
                              child: TransactionCardExpenses(
                                transaction: transaction,
                                tag: tag,
                                key: ValueKey(transaction.id),
                              ),
                            );

                            return Stack(
                              children: [
                                PieMenu(
                                  key: ValueKey(transaction.id),
                                  actions: pieMenuCrmExpenses(
                                    ref,
                                    transaction.id,
                                    transaction.id,
                                    context,
                                  ),
                                  onPressedWithDevice: (kind) {
                                    if (kind == PointerDeviceKind.mouse ||
                                        kind == PointerDeviceKind.touch) {
                                      if (isMobile) {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor:
                                              theme.dashboardContainer,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                          ),
                                          builder: (context) {
                                            return DraggableScrollableSheet(
                                              initialChildSize: 0.85,
                                              minChildSize: 0.4,
                                              maxChildSize: 0.95,
                                              expand: false,
                                              builder:
                                                  (context, scrollController) =>
                                                      ExpensesViewDetailsWidget(
                                                        transaction:
                                                            transaction,
                                                        isMobile: isMobile,
                                                        scrollController:
                                                            scrollController,
                                                      ),
                                            );
                                          },
                                        );
                                      } else {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return Dialog(
                                              insetPadding:
                                                  const EdgeInsets.all(24),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: SizedBox(
                                                height: screenSize.height / 1.2,
                                                width: screenSize.width / 1.2,
                                                child:
                                                    ExpensesViewDetailsWidget(
                                                      transaction: transaction,
                                                    ),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    }
                                  },
                                  child: DndReceiver(
                                    showSnackbar: false,
                                    targets: const [DndTargetType.expensesCard],
                                    showHoverFeedback: false,
                                    onDrop: (payload) {
                                      final incomingTransaction =
                                          payload.data!['transaction']
                                              as TransactionExpensesModel;
                                      onMove(
                                        incomingTransaction,
                                        status,
                                        index,
                                      );
                                    },
                                    builder: (
                                      context,
                                      hoveringPayload,
                                      isHovering,
                                      canAccept,
                                      innerChild,
                                    ) {
                                      return Column(
                                        children: [
                                          if (isHovering &&
                                              canAccept &&
                                              hoveringPayload != null)
                                            Container(
                                              color: AppColors.light50,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  15.0,
                                                ),
                                                child: SizedBox(
                                                  width: 300,
                                                  child: TransactionCardExpenses(
                                                    transaction:
                                                        hoveringPayload
                                                                .data!['transaction']
                                                            as TransactionExpensesModel,
                                                    tag: tag,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          innerChild!,
                                        ],
                                      );
                                    },
                                    child: DndSender(
                                      payload: DndPayload(
                                        type: DndPayloadType.expenses,
                                        id: transaction.id.toString(),
                                        action: 'move_to_column',
                                        subActions: ['assign_expense'],
                                        data: {'transaction': transaction},
                                      ),
                                      useLongPress: isMobile,
                                      feedbackBuilder:
                                          (context) => Material(
                                            color: Colors.transparent,
                                            child: Opacity(
                                              opacity: 0.7,
                                              child: card,
                                            ),
                                          ),
                                      child: card,
                                    ),
                                  ),
                                ),

                                // TO DO: to version 2.0 add here check to set it as paid (same for revenue card)

                                // Positioned(
                                //   right: 2,
                                //   top: 2,
                                //   child: IconButton(
                                //     icon: AppIcons.check(
                                //       color: theme.textColor,
                                //     ),
                                //     onPressed: () async {
                                //       final confirmed = await showDialog(
                                //         context: context,
                                //         builder:
                                //             (context) => AlertDialog(
                                //               title: Text('Potwierdzenie'.tr),
                                //               content: Text(
                                //                 'Jesteś pewnien że chcesz usunąć ten przychód?'
                                //                     .tr,
                                //               ),
                                //               actions: [
                                //                 TextButton(
                                //                   onPressed:
                                //                       () => ref
                                //                           .read(
                                //                             navigationService,
                                //                           )
                                //                           .beamPop(false),
                                //                   child: Text('Anuluj'.tr),
                                //                 ),
                                //                 TextButton(
                                //                   onPressed:
                                //                       () => ref
                                //                           .read(
                                //                             navigationService,
                                //                           )
                                //                           .beamPop(true),
                                //                   child: Text('Usuń'.tr),
                                //                 ),
                                //               ],
                                //             ),
                                //       );

                                //       if (confirmed == true) {
                                //         await ref
                                //             .read(removeCrmExpensesProvider)
                                //             .removeCrmExpenses(transaction.id);
                                //       }
                                //     },
                                //   ),
                                // ),
                              ],
                            );
                          }),
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              style: elevatedButtonStyleRounded10,
                              onPressed: () {
                                if (isMobile) {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: theme.dashboardContainer,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                    ),
                                    builder: (context) {
                                      return DraggableScrollableSheet(
                                        initialChildSize: 0.85,
                                        minChildSize: 0.4,
                                        maxChildSize: 0.95,
                                        expand: false,
                                        builder:
                                            (context, scrollController) =>
                                                AddInvoiceScreen(
                                                  isMobile: isMobile,
                                                  scrollController:
                                                      scrollController,
                                                ),
                                      );
                                    },
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (BuildContext dialogContext) {
                                      return Dialog(
                                        insetPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 24,
                                            ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: SizedBox(
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.7,
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.85,
                                          child: AddInvoiceScreen(
                                            isMobile: false,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                              child: AppIcons.add(color: theme.textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Drop target at the end of the list
                  DndReceiver(
                    showSnackbar: false,
                    targets: const [DndTargetType.expensesCard],
                    showPreview: false,
                    showHoverFeedback: true,
                    hoverDecoration: const BoxDecoration(
                      color: AppColors.light50,
                    ),
                    onDrop: (payload) {
                      final incomingTransaction =
                          payload.data!['transaction']
                              as TransactionExpensesModel;
                      onMove(incomingTransaction, status, transactions.length);
                    },
                    child: const SizedBox(height: 10),
                  ),
                ],
              ),
            ),
          ),
          const CustomVerticalDivider(),
        ],
      ),
    );
  }
}
