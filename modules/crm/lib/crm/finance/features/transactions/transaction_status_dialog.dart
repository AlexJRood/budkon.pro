// edit_status_dialog.dart
import 'package:crm/data/finance/transaction_provider.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:crm/shared/models/transaction/transaction_status_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/theme/text_field.dart';

final editingStatusProvider = StateProvider<int?>((ref) => null);
final addingStatusProvider = StateProvider<bool>((ref) => false);
final addStatusFocusNodeProvider = Provider<FocusNode>((ref) => FocusNode());

final addStatusControllerProvider =
Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

final editStatusControllerProvider =
Provider.autoDispose.family<TextEditingController, String>((ref, initialValue) {
  final controller = TextEditingController(text: initialValue);
  controller.selection = TextSelection.fromPosition(
    TextPosition(offset: controller.text.length),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

class TransactionStatusDialog extends ConsumerWidget {
  final AgentTransactionModel? contact;
  final bool isFilter;

  const TransactionStatusDialog({
    super.key,
    required this.contact,
    required this.isFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(transactionProvider);
    final theme = ref.read(themeColorsProvider);

    return statusState.when(
      data: (transactionState) => Padding(
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
                  FocusScope.of(context).unfocus();
                  ref.read(addingStatusProvider.notifier).state = false;
                  ref.read(editingStatusProvider.notifier).state = null;
                },
                child: ReorderableListView.builder(
                  cacheExtent: 300.0,
                  itemCount: transactionState.statuses.length + 1,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;
                    _onReorder(ref, transactionState, oldIndex, newIndex);
                  },
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    if (index == transactionState.statuses.length) {
                      final isAdding = ref.watch(addingStatusProvider);
                      final focusNode = ref.watch(addStatusFocusNodeProvider);
                      final addController = ref.watch(addStatusControllerProvider);

                      return KeyedSubtree(
                        key: const ValueKey('add_button'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 25,
                          ),
                          child: isAdding
                              ? CoreTextField(
                            key: const ValueKey('add_status_field'),
                            label: 'Nowy status'.tr,
                            hintText: 'Wpisz nowy status...'.tr,
                            controller: addController,
                            autofocus: true,
                            focusNode: focusNode,
                            onSubmitted: (newValue) {
                              if (newValue.trim().isNotEmpty) {
                                final newStatus = TransactionStatus(
                                  id: DateTime.now().millisecondsSinceEpoch,
                                  statusName: newValue.trim(),
                                  statusIndex:
                                  transactionState.statuses.length,
                                  transactionIndex: [],
                                );
                                ref
                                    .read(transactionProvider.notifier)
                                    .createTransactionStatus(
                                  newStatus,
                                  ref,
                                );
                                addController.clear();
                              }
                              ref.read(addingStatusProvider.notifier).state =
                              false;
                            },
                          )
                              : SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              style: elevatedButtonStyleRounded10,
                              onPressed: () {
                                ref.read(addingStatusProvider.notifier).state =
                                true;
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                      () {
                                    focusNode.requestFocus();
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

                    final status = transactionState.statuses[index];

                    return KeyedSubtree(
                      key: ValueKey(status.id),
                      child: DragTarget<int>(
                        onWillAcceptWithDetails: (data) => true,
                        onAcceptWithDetails: (data) {},
                        builder: (context, candidateData, rejectedData) {
                          final isBeingDragged = candidateData.isNotEmpty;
                          final isEditing =
                              ref.watch(editingStatusProvider) == status.id;
                          final editController = ref.watch(
                            editStatusControllerProvider(status.statusName),
                          );

                          return ReorderableDragStartListener(
                            index: index,
                            child: Container(
                              color: isBeingDragged
                                  ? theme.textFieldColor.withAlpha(125)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: isEditing
                                  ? CoreTextField(
                                label: 'Edytuj status'.tr,
                                controller: editController,
                                autofocus: true,
                                onSubmitted: (newValue) {
                                  if (newValue.trim().isNotEmpty) {
                                    final updatedStatus = TransactionStatus(
                                      id: status.id,
                                      statusName: newValue.trim(),
                                      statusIndex: status.statusIndex,
                                      transactionIndex:
                                      status.transactionIndex,
                                    );
                                    ref
                                        .read(transactionProvider.notifier)
                                        .updateTransactionStatus(
                                      updatedStatus,
                                      ref,
                                    );
                                  }
                                  ref.read(editingStatusProvider.notifier).state =
                                  null;
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
                                  ref.read(addingStatusProvider.notifier).state =
                                  false;
                                  if (isFilter) {
                                    ref.read(navigationService).beamPop();
                                  } else if (contact != null) {
                                    ref
                                        .read(transactionProvider.notifier)
                                        .updateTransactionStatus(
                                      status,
                                      ref,
                                    );
                                    ref.read(navigationService).beamPop();
                                  }
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      style: elevatedButtonStyleRounded10,
                                      icon: AppIcons.pencil(
                                        color: theme.textColor,
                                      ),
                                      onPressed: () {
                                        FocusScope.of(context).unfocus();
                                        ref
                                            .read(
                                          addingStatusProvider.notifier,
                                        )
                                            .state = false;
                                        ref
                                            .read(
                                          editingStatusProvider.notifier,
                                        )
                                            .state = status.id;
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      style: elevatedButtonStyleRounded10,
                                      icon: AppIcons.delete(
                                        color: theme.textColor,
                                      ),
                                      onPressed: () async {
                                        FocusScope.of(context).unfocus();
                                        ref
                                            .read(
                                          addingStatusProvider.notifier,
                                        )
                                            .state = false;

                                        final confirmed =
                                        await _showDeleteConfirmationDialog(
                                          context,
                                          ref,
                                          status.statusName,
                                        );

                                        if (confirmed == true) {
                                          _deleteStatus(ref, status.id);
                                        }
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
      loading: () =>  Center(child: AppLottie.loading()),
      error: (error, stack) => Center(child: Text('Error: $error'.tr)),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(
      BuildContext context,
      WidgetRef ref,
      String statusName,
      ) {
    final theme = ref.read(themeColorsProvider);

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.popupcontainercolor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(
            'Potwierdzenie usunięcia'.tr,
            style: AppTextStyles.interMedium18.copyWith(
              color: theme.textColor,
            ),
          ),
          content: Text(
            '${'Czy na pewno chcesz usunąć status'.tr} "$statusName"?',
            style: AppTextStyles.interMedium14.copyWith(
              color: theme.textColor,
            ),
          ),
          actions: [
            TextButton(
              style: elevatedButtonStyleRounded10,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Anuluj'.tr,
                style: TextStyle(color: theme.textColor),
              ),
            ),
            ElevatedButton(
              style: buttonStyleRounded10ThemeRedWithPadding15,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Usuń'.tr,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onReorder(
      WidgetRef ref,
      TransactionState transactionState,
      int oldIndex,
      int newIndex,
      ) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final movedStatus = transactionState.statuses.removeAt(oldIndex);
    transactionState.statuses.insert(newIndex, movedStatus);

    final updatedStatuses =
    transactionState.statuses.asMap().entries.map((entry) {
      final index = entry.key;
      final status = entry.value;
      return TransactionStatus(
        id: status.id,
        statusName: status.statusName,
        statusIndex: index,
        transactionIndex: status.transactionIndex,
      );
    }).toList();

    ref.read(transactionProvider.notifier).reorderStatuses(updatedStatuses);
  }

  void _deleteStatus(WidgetRef ref, int id) {
    ref.read(transactionProvider.notifier).deleteTransactionStatus(id, ref);
  }
}