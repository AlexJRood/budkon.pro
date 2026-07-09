import 'dart:developer';

import 'package:crm/crm/finance/features/futures_selected_view_widget.dart';
import 'package:crm/crm_urls.dart';
import 'package:crm/crm/finance/features/revenue/columns_revenue_old.dart';
import 'package:crm/crm/finance/features/revenue/revenue_list/revenue_list_widget.dart';
import 'package:crm/crm/finance/features/revenue/revenue_list/selected_revenue_status_provider.dart';
import 'package:crm/crm/finance/features/revenue/revenue_provider.dart';
import 'package:crm/crm/finance/features/revenue/columns_revenue.dart';
import 'package:crm/crm/finance/features/revenue/revenue_status_model.dart';
import 'package:crm/shared/models/revenue_model.dart';
import 'package:flutter/foundation.dart';
import 'package:core/platform/platforms/html_utils_stub.dart'
    if (dart.library.html) 'package:core/platform/platforms/html_utils_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/route_constant.dart';
import 'package:core/common/custom_error_handler.dart';
import 'package:crm/shared/models/transaction/transaction_status_model.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/api_services.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/lottie.dart';
import 'package:core/theme/button_style.dart';
import 'package:core/theme/icons.dart';

import '../../../../data/clients/statuses_clients/contact_status_list.dart';

class CrmRevenueBoard extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final bool isMobile;

  const CrmRevenueBoard({super.key, required this.ref, this.isMobile = false});

  @override
  _CrmRevenueBoardState createState() => _CrmRevenueBoardState();
}

class _CrmRevenueBoardState extends ConsumerState<CrmRevenueBoard> {
  final TextEditingController revenueStatusController = TextEditingController();

  @override
  void dispose() {
    revenueStatusController.dispose();
    super.dispose();
  }

  void _openTransaction(AgentRevenueModel transaction) async {
    int? clientId = transaction.id;

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

  void onReorder(AgentRevenueModel transaction, int newIndex) {
    setState(() {
      final currentState = ref.read(revenueProvider);
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
        final removedTransactionId = status.transactionIndex.removeAt(oldIndex);

        if (newIndex > oldIndex) newIndex -= 1;
        status.transactionIndex.insert(newIndex, removedTransactionId);

        ref
            .read(revenueProvider.notifier)
            .reorderTransaction(oldIndex, newIndex, status.statusName);
      });

      if (kDebugMode) {
        debugPrint(
          'Updated state in onReorder: ${ref.read(revenueProvider).whenData((data) => data.statuses.firstWhere((status) => status.transactionIndex.contains(transaction.id)).transactionIndex)}'
              .tr,
        );
      }
    });
  }

  void onMove(AgentRevenueModel revenue, String newStatus, int? newIndex) {
    ref
        .read(revenueProvider.notifier)
        .moveTransaction(revenue, newStatus, newIndex);
  }

  void onAcceptColumn(String movedStatus, String targetStatus) {
    setState(() {
      final currentState = ref.read(revenueProvider);
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

          ref.read(revenueProvider.notifier).reorderStatuses(data.statuses);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionStateAsync = ref.watch(revenueProvider);
    final isListView = ref.watch(isListProvider);
    final selectedStatus = ref.watch(selectedRevenueStatusProvider.notifier);
    final selectedStatusValue = ref.watch(selectedRevenueStatusProvider);
    final theme = ref.watch(themeColorsProvider);
    final selectedTextColor = AppColors.white;
    final unselectedTextColor = theme.textColor;

    // add-status controls
    final focusNode = ref.watch(addStatusFocusNodeProvider);
    final isAdding = ref.watch(addingStatusProvider);

    return transactionStateAsync.when(
      data: (data) {
        final transactionsMap = {for (var tx in data.transactions) tx.id: tx};
        if (data.statuses.isEmpty) {
          return Center(child: AppLottie.noResults(size: 450));
        }

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
                        // All Button
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
                  child: RevenueListWidget(
                    data: data,
                    isMobile: widget.isMobile,
                  ),
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
                ...data.statuses.map((status) {
                  final filteredTransactions =
                      status.transactionIndex
                          .map((id) => transactionsMap[id])
                          .where((tx) => tx != null)
                          .cast<AgentRevenueModel>()
                          .toList();

                  return DraggableColumn(
                    key: ValueKey(status.id),
                    status: status.statusName,
                    revenues: filteredTransactions,
                    onAcceptColumn: (payload) {
                      log("movedStatus: ${payload.toString()}");
                      onAcceptColumn(payload, status.statusName);
                    },
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
                                key: const ValueKey('add_status_field'),
                                autofocus: true,
                                focusNode: focusNode,
                                controller: revenueStatusController,
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
                                onSubmitted: (newValue) {
                                  if (newValue.isNotEmpty) {
                                    final newStatus = RevenueStatusModel(
                                      id: DateTime.now().millisecondsSinceEpoch,
                                      statusName: newValue,
                                      statusIndex: data.statuses.length,
                                      transactionIndex: [],
                                    );
                                    ref
                                        .read(revenueProvider.notifier)
                                        .createRevenueStatusModel(newStatus)
                                        .whenComplete(() {
                                          revenueStatusController.clear();
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
                                      revenueStatusController.clear();
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
                                    onTap: () {
                                      if (revenueStatusController
                                          .text
                                          .isNotEmpty) {
                                        final newStatus = RevenueStatusModel(
                                          id:
                                              DateTime.now()
                                                  .millisecondsSinceEpoch,
                                          statusName:
                                              revenueStatusController.text,
                                          statusIndex: data.statuses.length,
                                          transactionIndex: [],
                                        );
                                        ref
                                            .read(revenueProvider.notifier)
                                            .createRevenueStatusModel(newStatus)
                                            .whenComplete(() {
                                              revenueStatusController.clear();
                                            });
                                      }
                                      ref
                                          .read(addingStatusProvider.notifier)
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
                                          'Add',
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
                // ---- /Add Status inline panel ----
              ],
            ),
          ),
        );
      },
      loading: () => Center(child: AppLottie.loading(size: 450)),
      error: (error, _) {
        if (kDebugMode) debugPrint(error.toString());
        return Center(child: AppLottie.error(size: 450));
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
