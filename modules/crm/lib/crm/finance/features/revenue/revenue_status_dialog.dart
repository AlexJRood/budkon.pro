// edit_status_dialog.dart
import 'package:crm/crm/finance/features/revenue/revenue_provider.dart';
import 'package:crm/crm/finance/features/revenue/revenue_status_model.dart';
import 'package:crm/shared/models/revenue_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/design.dart';

final editingStatusProvider = StateProvider<int?>((ref) => null);
final addingStatusProvider = StateProvider<bool>((ref) => false); // Nowy status
final addStatusFocusNodeProvider = Provider(
  (ref) => FocusNode(),
); // FocusNode dla pola dodawania

class RevenueStatusDialog extends ConsumerWidget {
  final AgentRevenueModel? contact;
  final bool isFilter;
  const RevenueStatusDialog({
    super.key,
    required this.contact,
    required this.isFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(revenueProvider);
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
          (revenueState) => Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                if (isFilter) ...[
                  Text(
                    'Filtruj statusy',
                    style: AppTextStyles.interMedium22.copyWith(
                      color: theme.textColor,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Zmień Status kontaktu'.tr,
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
                          revenueState.statuses.length +
                          1, // +1 dla przycisku dodawania
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        _onReorder(ref, revenueState, oldIndex, newIndex);
                      },
                      buildDefaultDragHandles:
                          false, // Usuwa domyślną ikonę przeciągania
                      itemBuilder: (context, index) {
                        if (index == revenueState.statuses.length) {
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
                                            final newStatus = RevenueStatusModel(
                                              id:
                                                  DateTime.now()
                                                      .millisecondsSinceEpoch, // Tymczasowy unikalny ID
                                              statusName: newValue,
                                              statusIndex:
                                                  revenueState.statuses.length,
                                              transactionIndex: [],
                                            );
                                            ref
                                                .read(revenueProvider.notifier)
                                                .createRevenueStatusModel(
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

                        final status = revenueState.statuses[index];

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
                                                    RevenueStatusModel(
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
                                                      revenueProvider.notifier,
                                                    )
                                                    .updateRevenueStatusModel(
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
                                                // ref.read(revenueProvider.notifier).fetchTransactions(status: status.id);
                                                ref
                                                    .read(navigationService)
                                                    .beamPop();
                                              } else if (contact != null) {
                                                ref
                                                    .read(
                                                      revenueProvider.notifier,
                                                    )
                                                    .updateRevenueStatusModel(
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
    RevenueState revenueState,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) {
      newIndex -= 1; // Kompensujemy przesunięcie przy usuwaniu
    }
    final movedStatus = revenueState.statuses.removeAt(oldIndex);
    revenueState.statuses.insert(newIndex, movedStatus);

    // Tworzymy nowe instancje statusów z zaktualizowanymi indeksami
    final updatedStatuses =
        revenueState.statuses.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          return RevenueStatusModel(
            id: status.id,
            statusName: status.statusName,
            statusIndex: index, // Zaktualizowany indeks
            transactionIndex: status.transactionIndex,
          );
        }).toList();

    // Wywołaj metodę z providera, która aktualizuje stan
    ref.read(revenueProvider.notifier).reorderStatuses(updatedStatuses);
  }

  void _deleteStatus(WidgetRef ref, int id) {
    ref.read(revenueProvider.notifier).deleteRevenueStatusModel(id);
  }
}
