import 'package:crm/crm/finance/features/expenses/columns_expenses.dart';
import 'package:crm/crm/finance/features/futures_selected_view_widget.dart';
import 'package:crm/data/finance/expenses_provider.dart';
import 'package:crm/shared/models/expense/expenses_status_model.dart';
import 'package:crm/shared/models/transaction/transaction_expenses_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/button_style.dart';

import 'expenses_list/espenses_list_widget.dart';
import 'expenses_list/selected_expenses_status_provider.dart';

final expensesAddingStatusProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final expensesAddStatusFocusNodeProvider = Provider.autoDispose<FocusNode>(
  (ref) => FocusNode(),
);

class CrmExpensesBoard extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final bool isMobile;

  const CrmExpensesBoard({super.key, required this.ref, this.isMobile = false});

  @override
  _CrmExpensesBoardState createState() => _CrmExpensesBoardState();
}

class _CrmExpensesBoardState extends ConsumerState<CrmExpensesBoard> {
  final TextEditingController _statusController = TextEditingController();

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  void _openTransaction(TransactionExpensesModel transaction) {}

  void onReorder(TransactionExpensesModel transaction, int newIndex) {
    setState(() {
      final currentState = ref.read(expensesTransactionProvider);
      currentState.whenData((data) {
        final status = data.statuses.firstWhere(
          (status) => status.transactionIndex.contains(transaction.id),
        );
        final oldIndex = status.transactionIndex.indexOf(transaction.id);

        final removedTransactionId = status.transactionIndex.removeAt(oldIndex);

        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        status.transactionIndex.insert(newIndex, removedTransactionId);

        ref
            .read(expensesTransactionProvider.notifier)
            .reorderTransaction(oldIndex, newIndex, status.statusName);
      });

      if (kDebugMode) {
        debugPrint(
          'Updated state in onReorder: ${ref.read(expensesTransactionProvider).whenData((data) => data.statuses.firstWhere((status) => status.transactionIndex.contains(transaction.id)).transactionIndex)}'
              .tr,
        );
      }
    });
  }

  void onMove(
    TransactionExpensesModel transaction,
    String newStatus,
    int? newIndex,
  ) {
    ref
        .read(expensesTransactionProvider.notifier)
        .moveTransaction(transaction, newStatus, newIndex);
  }

  void onAcceptColumn(String movedStatus, String targetStatus) {
    setState(() {
      final currentState = ref.read(expensesTransactionProvider);
      currentState.whenData((data) {
        final oldIndex = data.statuses.indexWhere(
          (s) => s.statusName == movedStatus,
        );
        final newIndex = data.statuses.indexWhere(
          (s) => s.statusName == targetStatus,
        );

        if (oldIndex != -1 && newIndex != -1) {
          final movedItem = data.statuses.removeAt(oldIndex);
          data.statuses.insert(newIndex, movedItem);

          ref
              .read(expensesTransactionProvider.notifier)
              .reorderStatuses(data.statuses);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionStateAsync = widget.ref.watch(expensesTransactionProvider);
    final selectedStatus = ref.watch(selectedExpensesStatusProvider.notifier);
    final selectedStatusValue = ref.watch(selectedExpensesStatusProvider);
    final isListView = ref.watch(isListProvider);
    final theme = ref.watch(themeColorsProvider);
    final selectedTextColor = AppColors.white;
    final unselectedTextColor = theme.textColor;

    final isAdding = ref.watch(expensesAddingStatusProvider);
    final focusNode = ref.watch(expensesAddStatusFocusNodeProvider);

    return transactionStateAsync.when(
      data: (data) {
        
        final transactionsMap = {for (var tx in data.transactions) tx.id: tx};

        if (isListView) {
          final statuses = data.statuses;

          return Padding(
            padding: const EdgeInsets.only(
              bottom: 15.0,
              right: 15,
              left: 15,
              top: 15,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (statuses.isEmpty)
                  const CircularProgressIndicator()
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 40,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  selectedStatusValue == 'All'
                                      ? theme.themeColor
                                      : Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(5),
                                ),
                                side: BorderSide(
                                  color: theme.textColor.withAlpha(128),
                                ),
                              ),
                            ),
                            onPressed: () => selectedStatus.setStatus('All'),
                            child: Text(
                              'All',
                              style: AppTextStyles.interMedium14dark.copyWith(
                                color:
                                    selectedStatusValue == 'All'
                                        ? selectedTextColor
                                        : unselectedTextColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ...statuses.map((status) {
                          final isSelected =
                              selectedStatusValue == status.statusName;

                          return SizedBox(
                            height: 40,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      isSelected
                                          ? theme.themeColor
                                          : Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                    side: BorderSide(
                                      color: theme.textColor.withAlpha(128),
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  selectedStatus.setStatus(status.statusName);
                                },
                                child: Text(
                                  status.statusName,
                                  style: AppTextStyles.interMedium14dark
                                      .copyWith(
                                        color:
                                            isSelected
                                                ? selectedTextColor
                                                : unselectedTextColor,
                                      ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: ExpensesListWidget(
                    data: data,
                    isMobile: widget.isMobile,
                  ),
                ),
              ],
            ),
          );
        }

        // Board (columns) view
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width,
            ),
            child: Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...data.statuses.map((status) {
                  final filteredTransactions =
                      status.transactionIndex
                          .map((id) => transactionsMap[id])
                          .where((tx) => tx != null)
                          .cast<TransactionExpensesModel>()
                          .toList();

                  return DraggableColumn(
                    key: ValueKey(status.id),
                    status: status.statusName,
                    transactions: filteredTransactions,
                    onAcceptColumn:
                        (movedStatus) =>
                            onAcceptColumn(movedStatus, status.statusName),
                    // FIX: pass (transaction, newIndex) not (oldIndex, newIndex)
                    onReorder:
                        (transaction, newIndex) =>
                            onReorder(transaction, newIndex),
                    onMove:
                        (transaction, newStatus, newIndex) =>
                            onMove(transaction, newStatus, newIndex),
                    ref: widget.ref,
                    onTransactionSelected: _openTransaction,
                  );
                }),

                SizedBox(
                  width: 300,
                  height: isAdding ? 145 : 45,
                  child:
                      isAdding
                          ? Column(
                            spacing: 10,
                            children: [
                              TextField(
                                key: const ValueKey(
                                  'add_status_field_expenses',
                                ),
                                autofocus: true,
                                focusNode: focusNode,
                                controller: _statusController,
                                decoration: InputDecoration(
                                  hintText: 'Wpisz nowy status...'.tr,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide.none,
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                ),
                                onSubmitted: (newValue) async {
                                  if (newValue.isNotEmpty) {
                                    final newStatus = ExpensesStatusModel(
                                      id:
                                          DateTime.now()
                                              .millisecondsSinceEpoch, // temp id
                                      statusName: newValue,
                                      statusIndex: data.statuses.length,
                                      transactionIndex: const [],
                                    );
                                    await ref
                                        .read(
                                          expensesTransactionProvider.notifier,
                                        )
                                        .createTransactionStatus(newStatus);
                                    _statusController.clear();
                                  }
                                  ref
                                      .read(
                                        expensesAddingStatusProvider.notifier,
                                      )
                                      .state = false;
                                },
                                onEditingComplete: () {
                                  ref
                                      .read(
                                        expensesAddingStatusProvider.notifier,
                                      )
                                      .state = false;
                                },
                              ),
                              Row(
                                spacing: 20,
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      ref
                                          .read(
                                            expensesAddingStatusProvider
                                                .notifier,
                                          )
                                          .state = false;
                                      _statusController.clear();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: theme.dashboardContainer,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Cancel'.tr,
                                          style: AppTextStyles.interBold
                                              .copyWith(color: theme.textColor),
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      if (_statusController.text.isNotEmpty) {
                                        final newStatus = ExpensesStatusModel(
                                          id:
                                              DateTime.now()
                                                  .millisecondsSinceEpoch,
                                          statusName: _statusController.text,
                                          statusIndex: data.statuses.length,
                                          transactionIndex: const [],
                                        );
                                        await ref
                                            .read(
                                              expensesTransactionProvider
                                                  .notifier,
                                            )
                                            .createTransactionStatus(newStatus);
                                        _statusController.clear();
                                      }
                                      ref
                                          .read(
                                            expensesAddingStatusProvider
                                                .notifier,
                                          )
                                          .state = false;
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: theme.themeColor,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Add'.tr,
                                          style: AppTextStyles.interBold
                                              .copyWith(
                                                color: theme.themeTextColor,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                          : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: elevatedButtonStyleRounded10,
                              onPressed: () {
                                ref
                                    .read(expensesAddingStatusProvider.notifier)
                                    .state = true;
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () {
                                    focusNode.requestFocus();
                                  },
                                );
                              },
                              child: AppIcons.add(color: theme.textColor),
                            ),
                          ),
                ),
                // ================================================
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Text('Failed to loadd transactions and statuses: $error'.tr),
          ),
    );
  }
}
