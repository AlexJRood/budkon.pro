import 'package:crm/crm/finance/features/futures_selected_view_widget.dart';
import 'package:crm/crm/finance/features/transactions/columns_transactions.dart';
import 'package:crm/crm_urls.dart';
import 'package:crm/crm/finance/features/transactions/transaction_list/selected_transaction_status_provider.dart';
import 'package:crm/crm/finance/features/transactions/transaction_list/transaction_list_widget.dart';
import 'package:crm/data/finance/transaction_provider.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:crm/shared/models/transaction/transaction_status_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api_services.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/lottie.dart';

import '../../../../data/clients/statuses_clients/contact_status_list.dart';

class CrmTransactionBoard extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final bool isMobile;

  const CrmTransactionBoard({
    super.key,
    required this.ref,
    this.isMobile = false,
  });

  @override
  _CrmTransacitonBoardState createState() => _CrmTransacitonBoardState();
}

class _CrmTransacitonBoardState extends ConsumerState<CrmTransactionBoard> {
  void _openTransaction(AgentTransactionModel transaction) async {
    int? clientId = transaction.client.id;

    try {
      await fetchClientById(clientId);
      if (!mounted) return;

      // Open the clients view, then deep-link the URL to this client's
      // transaction. `Routes.clientsViewFull` had no screen behind it — the
      // clients view lives at `Routes.proClients` ('/pro/clients').
      ref.read(navigationService).pushNamedScreen(Routes.proClients);
      updateUrl('/pro/clients/$clientId/Transakcje/${transaction.id}');
    } catch (error) {
      if (!mounted) return;

      final snackBar = Customsnackbar().showSnackBar(
        "Error".tr,
        'Błąd podczas pobierania klienta: $error'.tr,
        "error",
        () {
          fetchClientById(clientId);
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<UserContactModel> fetchClientById(int clientId) async {
    try {
      final response = await ApiServices.get(
        ref: ref,
        CrmUrls.singleUserContacts('$clientId'),
        hasToken: true,
      );
      if (response != null && response.statusCode == 200) {
        return UserContactModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load client'.tr);
      }
    } catch (e) {
      throw Exception('Failed to load client: $e'.tr);
    }
  }

  void onReorder(AgentTransactionModel transaction, int newIndex) {
    setState(() {
      final currentState = ref.read(transactionProvider);
      currentState.whenData((data) {
        final status = data.statuses.firstWhereOrNull(
          (status) => status.transactionIndex.contains(transaction.id),
        );

        if (status == null) {
          if (kDebugMode) {
            debugPrint(
              "Nie znaleziono statusu dla transakcji ID: ${transaction.id}",
            );
          }
          return;
        }

        final oldIndex = status.transactionIndex.indexOf(transaction.id);

        // Usuwamy element ze starej pozycji
        final removedTransactionId = status.transactionIndex.removeAt(oldIndex);

        // Wstawiamy element na nową pozycję
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        status.transactionIndex.insert(newIndex, removedTransactionId);

        // Aktualizujemy stan w providerze
        ref
            .read(transactionProvider.notifier)
            .reorderTransaction(oldIndex, newIndex, status.statusName);
      });

      if (kDebugMode) {
        debugPrint(
          'Updated state in onReorder: ${ref.read(transactionProvider).whenData((data) => data.statuses.firstWhere((status) => status.transactionIndex.contains(transaction.id)).transactionIndex)}'
              .tr,
        );
      }
    });
  }

  void onMove(
    AgentTransactionModel transaction,
    String newStatus,
    int? newIndex,
  ) {
    ref
        .read(transactionProvider.notifier)
        .moveTransaction(transaction, newStatus, newIndex);
  }

  void onAcceptColumn(String movedStatus, String targetStatus) {
    setState(() {
      final currentState = ref.read(transactionProvider);
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

          ref.read(transactionProvider.notifier).reorderStatuses(data.statuses);
        }
      });
    });
  }

  final transactionStatusController = TextEditingController();
  @override
  void dispose() {
    transactionStatusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionStateAsync = ref.watch(transactionProvider);
    final isListView = ref.watch(isListProvider);
    final theme = ref.watch(themeColorsProvider);
    final selectedStatus = ref.watch(
      selectedTransactionStatusProvider.notifier,
    );
    final selectedStatusValue = ref.watch(selectedTransactionStatusProvider);
    final focusNode = ref.watch(addStatusFocusNodeProvider);
    final isAdding = ref.watch(addingStatusProvider);

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
                  Center(child: AppLottie.noResults(size: 450))
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10.0),
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
                                  side: BorderSide(color: theme.bordercolor),
                                ),
                              ),
                              onPressed: () {
                                selectedStatus.setStatus('All');
                              },
                              child: Text(
                                'All',
                                style: AppTextStyles.interMedium14dark.copyWith(
                                  color:
                                      selectedStatusValue == 'All'
                                          ? theme.themeTextColor
                                          : theme.textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
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
                                    side: BorderSide(color: theme.bordercolor),
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
                                                ? theme.themeTextColor
                                                : theme.textColor,
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
                TransactionListWidget(
                  data: data,
                  isMobile: widget.isMobile,
                ),
              ],
            ),
          );
        }
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      data.statuses.map((status) {
                        debugPrint(
                          'younis jan 2: ${status.transactionIndex.length}',
                        );
                        final filteredTransactions =
                            status.transactionIndex
                                .map((id) => transactionsMap[id])
                                .where((tx) => tx != null)
                                .cast<AgentTransactionModel>()
                                .toList();

                        return DraggableColumn(
                          key: ValueKey(status.id),
                          status: status.statusName,
                          transactions: filteredTransactions,
                          onAcceptColumn:
                              (movedStatus) => onAcceptColumn(
                                movedStatus,
                                status.statusName,
                              ),
                          onReorder:
                              (transaction, newIndex) =>
                                  onReorder(transaction, newIndex),
                          onMove:
                              (transaction, newStatus, newIndex) =>
                                  onMove(transaction, newStatus, newIndex),
                          ref: ref,
                          onTransactionSelected: _openTransaction,
                        );
                      }).toList(),
                ),
                SizedBox(
                  width: 300,
                  height: isAdding ? 145 : 45,
                  child:
                      isAdding
                          ? Column(
                            spacing: 10,
                            children: [
                              TextField(
                                key: const ValueKey('add_status_field'),
                                autofocus: true,
                                focusNode: focusNode,
                                controller: transactionStatusController,
                                decoration: InputDecoration(
                                  hintText: 'Wpisz nowy status...',
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
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                ),
                                onSubmitted: (newValue) {
                                  if (newValue.isNotEmpty) {
                                    final newStatus = TransactionStatus(
                                      id:
                                          DateTime.now()
                                              .millisecondsSinceEpoch, // temp id
                                      statusName: newValue,
                                      statusIndex: data.statuses.length,
                                      transactionIndex: [],
                                    );
                                    ref
                                        .read(transactionProvider.notifier)
                                        .createTransactionStatus(newStatus, ref)
                                        .whenComplete(() {
                                          transactionStatusController.clear();
                                        });
                                  }
                                  ref
                                      .read(addingStatusProvider.notifier)
                                      .state = false;
                                },
                                onEditingComplete: () {
                                  ref
                                      .read(addingStatusProvider.notifier)
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
                                          .read(addingStatusProvider.notifier)
                                          .state = false;
                                      transactionStatusController.clear();
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
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
                                    onTap: () {
                                      if (transactionStatusController
                                          .text
                                          .isNotEmpty) {
                                        final newStatus = TransactionStatus(
                                          id:
                                              DateTime.now()
                                                  .millisecondsSinceEpoch, // temp id
                                          statusName:
                                              transactionStatusController.text,
                                          // ✅ FIX: use `data.statuses.length` (was transactionState.statuses.length)
                                          statusIndex: data.statuses.length,
                                          transactionIndex: [],
                                        );
                                        ref
                                            .read(transactionProvider.notifier)
                                            .createTransactionStatus(
                                              newStatus,
                                              ref,
                                            )
                                            .whenComplete(() {
                                              transactionStatusController
                                                  .clear();
                                            });
                                      }
                                      ref
                                          .read(addingStatusProvider.notifier)
                                          .state = false;
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: theme.themeColor,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Add ',
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
                                ref.read(addingStatusProvider.notifier).state =
                                    true;
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
              ],
            ),
          ),
        );
      },
      loading: () => Center(child: AppLottie.loading(size: 450)),
      error: (error, _) {
        if (kDebugMode) debugPrint(error.toString());
        return Center(
          child: Text('Failed to loaddd transactions and statuses: $error'.tr),
        );
      },
    );
  }

  void showEditStatusPopup(
    BuildContext context,
    WidgetRef ref, {
    TransactionStatus? status,
    required Function(TransactionStatus) onSave,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        String? statusName = status?.statusName ?? '';
        int? statusIndex = status?.statusIndex ?? 0;

        return AlertDialog(
          title: Text(status != null ? 'Edit Status'.tr : 'New Status'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: statusName,
                decoration: InputDecoration(labelText: 'Status Name'.tr),
                onChanged: (newValue) {
                  statusName = newValue;
                },
              ),
              TextFormField(
                initialValue: statusIndex.toString(),
                decoration: InputDecoration(labelText: 'Status Index'.tr),
                keyboardType: TextInputType.number,
                onChanged: (newValue) {
                  statusIndex = int.tryParse(newValue) ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'.tr),
              onPressed: () => ref.read(navigationService).beamPop(),
            ),
            ElevatedButton(
              child: Text('Save'.tr),
              onPressed: () {
                final newStatus = TransactionStatus(
                  id: status?.id ?? 0,
                  statusName: statusName!,
                  statusIndex: statusIndex!,
                  transactionIndex: status?.transactionIndex ?? [],
                );
                onSave(newStatus);
                ref.read(navigationService).beamPop();
              },
            ),
          ],
        );
      },
    );
  }
}

class EditStatusDialog extends ConsumerStatefulWidget {
  final TransactionStatus? status;
  final Function(TransactionStatus) onSave;

  const EditStatusDialog({super.key, this.status, required this.onSave});

  @override
  _EditStatusDialogState createState() => _EditStatusDialogState();
}

class _EditStatusDialogState extends ConsumerState<EditStatusDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _statusName;
  late int _statusIndex;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.status != null ? 'Edytuj Status'.tr : 'Nowy Status'.tr,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _statusName,
              decoration: InputDecoration(labelText: 'Nazwa Statusu'.tr),
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Wprowadź nazwę statusu'.tr
                          : null,
              onSaved: (value) => _statusName = value!,
            ),
            TextFormField(
              initialValue: _statusIndex.toString(),
              decoration: InputDecoration(labelText: 'Indeks Statusu'.tr),
              keyboardType: TextInputType.number,
              validator:
                  (value) =>
                      value == null || int.tryParse(value) == null
                          ? 'Wprowadź poprawny indeks'.tr
                          : null,
              onSaved: (value) => _statusIndex = int.parse(value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Anuluj'.tr),
          onPressed: () => ref.read(navigationService).beamPop(),
        ),
        ElevatedButton(
          child: Text('Zapisz'.tr),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final newStatus = TransactionStatus(
                id: widget.status?.id ?? 0,
                statusName: _statusName,
                statusIndex: _statusIndex,
                transactionIndex: widget.status?.transactionIndex ?? [],
              );
              widget.onSave(newStatus);
              ref.read(navigationService).beamPop();
            }
          },
        ),
      ],
    );
  }
}
