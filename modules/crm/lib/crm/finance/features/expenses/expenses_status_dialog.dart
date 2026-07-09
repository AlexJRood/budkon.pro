import 'package:crm/shared/models/transaction/transaction_expenses_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/design.dart';
import 'package:crm/shared/models/expense/expenses_status_model.dart';
import 'package:crm/data/finance/expenses_provider.dart';

final editingStatusProvider = StateProvider.autoDispose<int?>((ref) => null);
final addingStatusProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
); // Nowy status
final addStatusFocusNodeProvider = Provider.autoDispose(
  (ref) => FocusNode(),
); // FocusNode dla pola dodawania

class ExpensesStatusDialog extends ConsumerWidget {
  final TransactionExpensesModel? contact;
  final bool isFilter;
  const ExpensesStatusDialog({
    super.key,
    required this.contact,
    required this.isFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(expensesTransactionProvider);
    final theme = ref.read(themeColorsProvider);
    InputDecoration statusInputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.textColor.withAlpha(150)),
        filled: true,
        fillColor: theme.textFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.textColor.withAlpha(80)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.textColor.withAlpha(80)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.themeColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      );
    }

    return statusState.when(
      data:
          (expenseState) => Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                if (isFilter) ...[
                  Text(
                    'Filter statuses',
                    style: AppTextStyles.interMedium22.copyWith(
                      color: theme.textColor,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Manage expenses statuses'.tr,
                    style: AppTextStyles.interMedium22.copyWith(
                      color: theme.textColor,
                    ),
                  ),
                ],

                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      // Gdy użytkownik kliknie poza polem, schowaj pole dodawania
                      FocusScope.of(context).unfocus();
                      ref.read(addingStatusProvider.notifier).state = false;
                      ref.read(editingStatusProvider.notifier).state = null;
                    },
                    child: ReorderableListView.builder(
                      cacheExtent: 300.0,
                      itemCount:
                          expenseState.statuses.length +
                          1, // +1 dla przycisku dodawania
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        _onReorder(ref, expenseState, oldIndex, newIndex);
                      },
                      buildDefaultDragHandles:
                          false, // Usuwa domyślną ikonę przeciągania
                      itemBuilder: (context, index) {
                        if (index == expenseState.statuses.length) {
                          // Ostatni element - pole do dodawania nowego statusu
                          final isAdding = ref.watch(addingStatusProvider);
                          final focusNode = ref.watch(
                            addStatusFocusNodeProvider,
                          );

                          return KeyedSubtree(
                            key: const ValueKey(
                              'add_button',
                            ), // Unikalny key dla przycisku
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 25,
                              ),
                              child:
                                  isAdding
                                      ? TextField(
                                        key: const ValueKey(
                                          'add_status_field',
                                        ), // Klucz dla pola tekstowego
                                        autofocus: true,
                                        focusNode:
                                            focusNode, // Przypisujemy FocusNode
                                        controller: TextEditingController(),
                                        decoration: statusInputDecoration(
                                          'Wpisz nowy status...'.tr,
                                        ),
                                        style: TextStyle(
                                          color: theme.textColor,
                                        ),
                                        cursorColor: theme.themeColor,
                                        keyboardAppearance:
                                            Theme.of(context).brightness,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (newValue) {
                                          if (newValue.isNotEmpty) {
                                            final newStatus = ExpensesStatusModel(
                                              id:
                                                  DateTime.now()
                                                      .millisecondsSinceEpoch, // Tymczasowy unikalny ID
                                              statusName: newValue,
                                              statusIndex:
                                                  expenseState.statuses.length,
                                              transactionIndex: [],
                                            );
                                            ref
                                                .read(
                                                  expensesTransactionProvider
                                                      .notifier,
                                                )
                                                .createTransactionStatus(
                                                  newStatus,
                                                );
                                          }
                                          ref
                                                  .read(
                                                    addingStatusProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              false; // Ukryj pole po dodaniu
                                        },
                                        onEditingComplete: () {
                                          ref
                                                  .read(
                                                    addingStatusProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              false; // Ukryj pole po kliknięciu poza nim
                                        },
                                      )
                                      : SizedBox(
                                        width: double.infinity,
                                        height: 45,
                                        child: ElevatedButton(
                                          style: elevatedButtonStyleRounded10,
                                          onPressed: () {
                                            ref
                                                .read(
                                                  addingStatusProvider.notifier,
                                                )
                                                .state = true;
                                            Future.delayed(
                                              Duration(milliseconds: 100),
                                              () {
                                                focusNode
                                                    .requestFocus(); // Automatyczne ustawienie focusa
                                              },
                                            );
                                          },
                                          child: AppIcons.add(
                                            color: theme.textColor,
                                          ),
                                        ),
                                      ),
                            ),
                          );
                        }

                        final status = expenseState.statuses[index];

                        return KeyedSubtree(
                          key: ValueKey(status.id),
                          child: DragTarget<int>(
                            onWillAcceptWithDetails: (data) => true,
                            onAcceptWithDetails: (data) {},
                            builder: (context, candidateData, rejectedData) {
                              final isBeingDragged = candidateData.isNotEmpty;
                              final isEditing =
                                  ref.watch(editingStatusProvider) == status.id;

                              return ReorderableDragStartListener(
                                index: index,
                                child: Container(
                                  color:
                                      isBeingDragged
                                          ? theme.textFieldColor.withAlpha(125)
                                          : Colors
                                              .transparent, // Zmiana koloru przy przeciąganiu
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  child:
                                      isEditing
                                          ? TextField(
                                            autofocus: true,
                                            controller: TextEditingController(
                                                text: status.statusName,
                                              )
                                              ..selection =
                                                  TextSelection.fromPosition(
                                                    TextPosition(
                                                      offset:
                                                          status
                                                              .statusName
                                                              .length,
                                                    ),
                                                  ),
                                            decoration: statusInputDecoration(
                                              'Status'.tr,
                                            ),
                                            style: TextStyle(
                                              color: theme.textColor,
                                            ),
                                            cursorColor: theme.themeColor,
                                            keyboardAppearance:
                                                Theme.of(context).brightness,
                                            textInputAction:
                                                TextInputAction.done,
                                            onSubmitted: (newValue) {
                                              if (newValue.isNotEmpty) {
                                                final updatedStatus =
                                                    ExpensesStatusModel(
                                                      id: status.id,
                                                      statusName: newValue,
                                                      statusIndex:
                                                          status.statusIndex,
                                                      transactionIndex:
                                                          status
                                                              .transactionIndex,
                                                    );
                                                ref
                                                    .read(
                                                      expensesTransactionProvider
                                                          .notifier,
                                                    )
                                                    .updateTransactionStatus(
                                                      updatedStatus,
                                                    );
                                              }
                                              ref
                                                      .read(
                                                        editingStatusProvider
                                                            .notifier,
                                                      )
                                                      .state =
                                                  null; // Wyłącz edycję
                                            },
                                          )
                                          : ListTile(
                                            title: Text(
                                              status.statusName,
                                              style: AppTextStyles.interMedium14
                                                  .copyWith(
                                                    color: theme.textColor,
                                                  ),
                                            ),
                                            onTap: () {
                                              FocusScope.of(context).unfocus();
                                              ref
                                                  .read(
                                                    addingStatusProvider
                                                        .notifier,
                                                  )
                                                  .state = false;
                                              if (isFilter) {
                                                // ref.read(transactionProvider.notifier).fetchTransactions(status: status.id);
                                                ref
                                                    .read(navigationService)
                                                    .beamPop();
                                              } else if (contact != null) {
                                                ref
                                                    .read(
                                                      expensesTransactionProvider
                                                          .notifier,
                                                    )
                                                    .updateTransactionStatus(
                                                      status,
                                                    );
                                                ref
                                                    .read(navigationService)
                                                    .beamPop();
                                              }
                                            },
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  style:
                                                      elevatedButtonStyleRounded10,
                                                  icon: AppIcons.pencil(
                                                    color: theme.textColor,
                                                  ),
                                                  onPressed: () {
                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
                                                    ref
                                                        .read(
                                                          addingStatusProvider
                                                              .notifier,
                                                        )
                                                        .state = false;
                                                    ref
                                                        .read(
                                                          editingStatusProvider
                                                              .notifier,
                                                        )
                                                        .state = status
                                                            .id; // Włącza edycję
                                                  },
                                                ),
                                                const SizedBox(width: 10),
                                                IconButton(
                                                  style:
                                                      elevatedButtonStyleRounded10,
                                                  icon: AppIcons.delete(
                                                    color: theme.textColor,
                                                  ),
                                                  onPressed: () {
                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
                                                    ref
                                                        .read(
                                                          addingStatusProvider
                                                              .notifier,
                                                        )
                                                        .state = false;
                                                    _deleteStatus(
                                                      ref,
                                                      status.id,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error'.tr)),
    );
  }

  void _onReorder(
    WidgetRef ref,
    ExpensesState expenseState,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) {
      newIndex -= 1; // Kompensujemy przesunięcie przy usuwaniu
    }
    final movedStatus = expenseState.statuses.removeAt(oldIndex);
    expenseState.statuses.insert(newIndex, movedStatus);

    // Tworzymy nowe instancje statusów z zaktualizowanymi indeksami
    final updatedStatuses =
        expenseState.statuses.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          return ExpensesStatusModel(
            id: status.id,
            statusName: status.statusName,
            statusIndex: index, // Zaktualizowany indeks
            transactionIndex: status.transactionIndex,
          );
        }).toList();

    // Wywołaj metodę z providera, która aktualizuje stan
    ref
        .read(expensesTransactionProvider.notifier)
        .reorderStatuses(updatedStatuses);
  }

  void _deleteStatus(WidgetRef ref, int id) {
    ref.read(expensesTransactionProvider.notifier).deleteTransactionStatus(id);
  }
}
