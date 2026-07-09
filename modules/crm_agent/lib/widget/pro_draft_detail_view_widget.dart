import 'package:crm/data/clients/client_selection_provider.dart';
import 'package:core/shell/pop_manager/pop_page_manager.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:crm/contact_panel/tabs/transactions/tx_client_provider.dart';
import 'package:crm/data/finance/transaction_provider.dart';
import 'package:crm/widget/transaction_manage_panel.dart';
import 'package:crm_agent/add_client_form/add_client_form_page.dart';
import 'package:crm_agent/add_client_form/components/usercontact/add_user_contacts.dart';
import 'package:crm_agent/add_client_form/components/usercontact/usercontact_custom_drop_down.dart';
import 'package:crm/data/clients/contact_type_provider.dart';
import 'package:crm/shared/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';

import 'package:crm_agent/add_client_form/components/transaction/transaction_custom_drop_down.dart';
import 'package:crm/crm/clients/components/user_contact_custom_text_field.dart';
import 'package:crm_agent/add_client_form/controllers/transaction_controlers.dart';
import 'package:crm_agent/add_client_form/provider/send_form_provider.dart';
import 'package:crm_agent/add_client_form/provider/transaction_provider.dart';
import 'package:crm/shared/models/clients_model.dart';
import 'package:crm/invoices/form/provider/form_provider.dart';
import 'package:core/platform/navigation_service.dart';

import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/backgroundgradient.dart';

import 'package:shimmer/shimmer.dart';
import 'package:crm/data/clients/client_provider.dart';

import 'package:core/platform/api_services.dart';
import 'package:core/platform/url.dart';
import 'package:core/platform/api/toggle_button.dart';

import 'package:flutter/services.dart';

// --------------------------- WRAPPER ---------------------------

class ProDraftDetailViewWidget extends ConsumerWidget {
  final AgentTransactionModel transaction;
  final bool isMobile;
  const ProDraftDetailViewWidget({super.key, this.isMobile = false, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SizedBox(height: isMobile ? TopAppBarSize.resolve(context) : 20),
        
            // wybór/utworzenie klienta
            if (!ref.watch(showUserContactsProvider)) ...[
              ClientListAddFormCrm(contact: transaction.client),
            ] else ...[
              Row(
                spacing: 30,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: AddUserContactsCrm())],
              ),
            ],
        
            const SizedBox(height: 20),
        
            // nowy widget z detalami transakcji
            TransactionDetailsEditor(
              isMobile: isMobile,
              key: ValueKey((transaction.id == 0) ? 'new' : transaction.id),
              transaction: transaction,
            ),
            const SizedBox(height: 20),
        
            TransactionManagePanel(
              isMobile: isMobile,
              transaction: transaction,
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------- NOWY WIDGET ---------------------------

final transactionDetailsChangedProvider = StateProvider<bool>((ref) => false);

class TransactionDetailsEditor extends ConsumerStatefulWidget {
  final bool isMobile;
  final AgentTransactionModel? transaction;

  const TransactionDetailsEditor({
    super.key,
    this.isMobile = false,
    required this.transaction,
  });

  @override
  ConsumerState<TransactionDetailsEditor> createState() => _TransactionDetailsEditorState();
}

class _TransactionDetailsEditorState extends ConsumerState<TransactionDetailsEditor> {

  late final String _dropdownScope;


@override
void initState() {
  super.initState();

  _dropdownScope =
      'tx_editor_${widget.transaction?.id ?? 'new'}_${identityHashCode(this)}';

  getData();

  final ctrls = ref.read(transactionControllersProvider);
  final tx = widget.transaction;

  if (tx != null) {
    ctrls.nameController.text = tx.name;
    ctrls.amountController.text = tx.amount;
    ctrls.commissionController.text = tx.commission;
    ctrls.isCommisssionPercentage.value = tx.isCommisssionPercentage;
    ctrls.isCommissionNetValue.value = tx.isCommissionNetValue;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final cache = ref.read(agentTransactionCacheProvider.notifier);
    if (tx != null) {
      cache.addTransactionData('name', tx.name);
      cache.addTransactionData('amount', tx.amount);
      cache.addTransactionData('commission', tx.commission);
      cache.addTransactionData('currency', tx.currency);
      cache.addTransactionData('payment_methods', tx.paymentMethods);
      cache.addTransactionData('transaction_type', tx.transactionType);
      cache.addTransactionData('status', tx.status);
      cache.addTransactionData('isCommisssionPercentage', tx.isCommisssionPercentage);
      cache.addTransactionData('isCommissionNetValue', tx.isCommissionNetValue);
      cache.addTransactionData('responsible_person', tx.responsiblePersonId);
    }
  });
}


  void getData() async {
    final provider = ref.read(contactTypeProvider);
    await Future.wait([
      provider.getUserDetails(ref),
    ]);
    provider.resetState();
  }

  bool _isInsidePopup(BuildContext context) => context.findAncestorWidgetOfExactType<PopPageManager>() != null;

  void _setChanged() => ref.read(transactionDetailsChangedProvider.notifier).state = true;

  /// ✅ wylicza jednostkę do pokazania za cyframi w polu commission
  String _resolveCommissionUnit({
    required bool isPercent,
    required String? selectedCurrency,
  }) {
    if (isPercent) return '%';
    return (selectedCurrency == null || selectedCurrency.trim().isEmpty) ? '' : selectedCurrency.trim();
  }

  /// ✅ próba wyciągnięcia waluty z dropdown cache / provider
  String? _getSelectedCurrencyFromUi() {
    final cache = ref.read(agentTransactionCacheProvider);
    final fromCache = cache['currency'];
    if (fromCache is String && fromCache.trim().isNotEmpty) return fromCache.trim();

    // fallback: jeżeli trzymasz dropdowny w agentTransactionDropDownProvider
    final ddMap = ref.read(agentTransactionDropDownProvider);
    for (final d in ddMap.values) {
      if (d.valueKey == 'currency') {
        final v = d.selectedValue;
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return null;
  }

  void _onPercentToggleChanged(bool val) {
    final ctrls = ref.read(transactionControllersProvider);
    final cacheN = ref.read(agentTransactionCacheProvider.notifier);

    ctrls.isCommisssionPercentage.value = val;
    cacheN.addTransactionData('isCommisssionPercentage', val);

    if (val == true) {
      // ✅ procent => waluta nie ma sensu
      cacheN.addTransactionData('currency', null);
      // jeżeli masz dropdown provider z selectedValue, też warto go wyczyścić:
      // ref.read(agentTransactionDropDownProvider.notifier).clearByKey('currency');
    }

    _setChanged();
  }

@override
void dispose() {
  ref.read(sellOfferDropDownProvider.notifier).resetScope(_dropdownScope);
  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    final cache = ref.read(agentTransactionCacheProvider.notifier);
    final ctrls = ref.watch(transactionControllersProvider);
    final theme = ref.watch(themeColorsProvider);

    final isPopup = _isInsidePopup(context);
    final isChanged = ref.watch(transactionDetailsChangedProvider);
    final contactTypeState = ref.watch(contactTypeProvider);

    Widget percentToggle() {
      return SizedBox(
        height: 50,
        child: ValueListenableBuilder<bool>(
          valueListenable: ctrls.isCommisssionPercentage,
          builder: (context, isPercent, _) {
            return SegmentedIconToggle<bool>(
              options: [
                ToggleOption<bool>(
                  value: false,
                  label: 'fixed_amount_label'.tr,
                  iconBuilder: ({Color? color}) => AppIcons.dollar(color: color),
                ),
                ToggleOption<bool>(
                  value: true,
                  label: 'percent_label'.tr,
                  iconBuilder: ({Color? color}) => AppIcons.percent(color: color),
                ),
              ],
              selected: isPercent,
              onChanged: _onPercentToggleChanged,
              itemWidth: 45,
              itemHeight: 45,
              iconSize: 22,
              spacing: 0,
              selectedBg: theme.themeColor,
              unselectedBg: theme.dashboardContainer,
              selectedFg: theme.themeTextColor,
              unselectedFg: theme.textColor.withAlpha((255 * 0.50).toInt()),
            );
          },
        ),
      );
    }

    Widget currencyDropdown({int? txId, String? initial}) {
      return ValueListenableBuilder<bool>(
        valueListenable: ctrls.isCommisssionPercentage,
        builder: (context, isPercent, _) {
          // ✅ procent => pole waluty znika w 100%
          if (isPercent) return const SizedBox.shrink();

          return AgentTransactionFormCustomDropDown(
            id: 8,
            options: const ['PLN', 'EUR', 'USD'],
            hintText: 'Currency'.tr,
            valueKey: 'currency',
            txId: txId,
            initialValue: initial,
            onChanged: _setChanged,
          );
        },
      );
    }

    Widget commissionFieldWithUnit() {
      return ValueListenableBuilder<bool>(
        valueListenable: ctrls.isCommisssionPercentage,
        builder: (context, isPercent, _) {
          final currency = _getSelectedCurrencyFromUi() ?? widget.transaction?.currency;
          final unit = _resolveCommissionUnit(isPercent: isPercent, selectedCurrency: currency);

return UserContactCustomTextField(
  id: 28,
  valueKey: 'commission',
  hintText: 'commission_label'.tr,
  controller: ctrls.commissionController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^[0-9., ]*$')),
    TextInputFormatter.withFunction((oldValue, newValue) {
      final t = newValue.text;
      final dots = '.'.allMatches(t).length;
      final commas = ','.allMatches(t).length;
      if (dots + commas > 1) return oldValue;
      return newValue;
    }),
  ],
  normalizeCommaToDot: true,
  formatThousands: true,
  thousandSeparator: ' ',
  inlineSuffixText: unit.isEmpty ? null : unit,
  onChanged: (key, val) {
    cache.addTransactionData(key, val); // val jest RAW, np "1000000.5"
    _setChanged();
  },
);


        },
      );
    }

// ---------------- POPUP ----------------
    if (isPopup) {
      return Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
            Expanded(
              child: Container(
                color: theme.dashboardContainer,
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 12,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UserContactCustomTextField(
                        id: 99,
                        valueKey: 'name',
                        hintText:'title_label'.tr,
                        controller: ctrls.nameController,
                        validator: (v) => (v == null || v.isEmpty) ? 'title_cannot_be_empty'.tr : null,
                        onChanged: (key, val) {
                          cache.addTransactionData(key, val);
                          _setChanged();
                        },
                      ),

                      Divider(color: theme.textColor.withAlpha(120)),
                      Row(
                        children: [
                          Expanded(
                            child: AgentTransactionFormCustomDropDown(
                              id: 7,
                              options: ['cash_payment'.tr, 'transfer_payment'.tr,'cash_payment'.tr],
                              hintText: 'payment_method_label'.tr,
                              valueKey: 'payment_methods',
                              txId: widget.transaction?.id,
                              initialValue: widget.transaction?.paymentMethods,
                              onChanged: _setChanged,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AddClientFormCustomDropDown(
                              id: 104,
                              hintText: 'service_type_label'.tr,
                              valueKey: 'service_type',
                              scopeKey: _dropdownScope,
                              options: contactTypeState.contactServiceType.map((e) => e.displayLabel).toList(),
                              values: contactTypeState.contactServiceType.map((e) => e.idAsString).toList(),
                              onChangedExtra: (newValue, id, valueKey) {},
                            ),
                          ),
                        ],
                      ),

                      Divider(color: theme.textColor.withAlpha(120)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          percentToggle(),
                          const SizedBox(width: 12),
                          Expanded(flex: 4, child: commissionFieldWithUnit()),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: currencyDropdown(
                              txId: widget.transaction?.id,
                              initial: widget.transaction?.currency,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ValueListenableBuilder<bool>(
                            valueListenable: ctrls.isCommissionNetValue,
                            builder: (context, isNetValue, _) {
                              return SizedBox(
                                width: 200,
                                child: SegmentedIconToggle<bool>(
                                  options: [
                                    ToggleOption<bool>(
                                      value: true,
                                      label: 'netto_label'.tr,
                                      iconBuilder: ({Color? color}) => Text(
                                        'netto_label'.tr,
                                        style: TextStyle(color: color),
                                      ),
                                    ),
                                    ToggleOption<bool>(
                                      value: false,
                                      label: 'brutto_label'.tr,
                                      iconBuilder: ({Color? color}) => Text(
                                        'brutto_label'.tr,
                                        style: TextStyle(color: color),
                                      ),
                                    ),
                                  ],
                                  selected: isNetValue,
                                  onChanged: (val) {
                                    ctrls.isCommissionNetValue.value = val;
                                    ref.read(agentTransactionCacheProvider.notifier)
                                        .addTransactionData('isCommissionNetValue', val);
                                    ref.read(transactionDetailsChangedProvider.notifier).state = true;
                                  },
                                  itemWidth: 100,
                                  itemHeight: 45,
                                  iconSize: 22,
                                  spacing: 0,
                                  selectedBg: theme.themeColor,
                                  unselectedBg: theme.dashboardContainer,
                                  selectedFg: theme.themeTextColor,
                                  unselectedFg: theme.textColor.withAlpha((255 * 0.50).toInt()),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (isChanged) _buildSubmitBar(context, ref),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // ---------------- STANDARD (PC/MOBILE) ----------------
    return Column(
      children: [
        // Nagłówek
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: theme.themeColor,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(6), topLeft: Radius.circular(6)),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'transaction_details_title'.tr,
                style: TextStyle(
                  color: theme.themeTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if ((widget.transaction?.id ?? 0) == 0) AppIcons.iosArrowDown(color: theme.themeTextColor),
            ],
          ),
        ),

        // Body
        Container(
          decoration: BoxDecoration(color: theme.dashboardContainer),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 12,
            children: [
              if (!widget.isMobile) ...[
                Row(
                  children: [
                    Expanded(
                      child: UserContactCustomTextField(
                        formatThousands: false,
                        id: 99,
                        valueKey: 'name',
                        hintText: 'Title'.tr,
                        controller: ctrls.nameController,
                        validator: (v) => (v == null || v.isEmpty) ? "Title can't be empty".tr : null,
                        onChanged: (key, val) {
                          cache.addTransactionData(key, val);
                          _setChanged();
                        },
                      ),
                    ),
                  ],
                ),
                Divider(color: theme.textColor.withAlpha(120)),

                Row(
                  children: [
                    Expanded(
                      child: AgentTransactionFormCustomDropDown(
                        id: 7,
                        options: ['Cash'.tr, 'Transfer'.tr, 'Card'.tr],
                        hintText: 'Payment Method'.tr,
                        valueKey: 'payment_methods',
                        txId: widget.transaction?.id,
                        initialValue: widget.transaction?.paymentMethods,
                        onChanged: _setChanged,
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: AddClientFormCustomDropDown(
                        id: 104,
                        hintText: 'Service Type'.tr,
                        valueKey: 'service_type',
                        options: contactTypeState.contactServiceType.map((e) => e.displayLabel).toList(),
                        values: contactTypeState.contactServiceType.map((e) => e.idAsString).toList(),
                        onChangedExtra: (newValue, id, valueKey) {},
                      ),
                    ),
                  ],
                ),

                    Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: AddClientFormCustomDropDown(
                          id: 2013,
                          scopeKey: _dropdownScope,
                          hintText: 'responsible_person_label'.tr,
                          valueKey: 'responsible_person',
                          initialValue: widget.transaction?.responsiblePersonId?.toString(), // ✅ NEW
                          options: contactTypeState.userModel?.companyMembers
                                  .map((m) => '${m.firstName} ${m.lastName}')
                                  .toList() ??
                              const [],
                          values: contactTypeState.userModel?.companyMembers
                                  .map((m) => m.id.toString())
                                  .toList() ??
                              const [],
                          onChangedExtra: (newValue, id, valueKey) {
                            // ✅ to jest prawdziwe źródło dla transakcji
                            ref
                                .read(agentTransactionCacheProvider.notifier)
                                .addTransactionData(valueKey, newValue);
                            ref.read(transactionDetailsChangedProvider.notifier).state = true;
                          },
                        ),
                      ),
                    ],
                  ),

                Divider(color: theme.textColor.withAlpha(120)),

                Row(
                  children: [
                    percentToggle(),
                    const SizedBox(width: 12),

                    Expanded(flex: 4, child: commissionFieldWithUnit()),
                    const SizedBox(width: 12),

                    SizedBox(width: 110, child: currencyDropdown()),

                    
                    const SizedBox(width: 12),

                     ValueListenableBuilder<bool>(
                        valueListenable: ctrls.isCommissionNetValue,
                        builder: (context, isPercent, _) {
                          return SegmentedIconToggle<bool>(
                            options: [
                              ToggleOption<bool>(
                                value: true,
                                label: 'net_amount_label'.tr,
                                iconBuilder: ({Color? color}) => Text('netto_label'.tr, style: TextStyle(color: color)),
                              ),
                              ToggleOption<bool>(
                                value: false,
                                label: 'gross_amount_label'.tr,
                                iconBuilder: ({Color? color}) => Text('brutto_label'.tr, style: TextStyle(color: color)),
                              ),
                            ],
                            selected: isPercent,
                            onChanged: (val) {
                              ctrls.isCommissionNetValue.value = val;
                              ref.read(agentTransactionCacheProvider.notifier)
                                .addTransactionData('isCommissionNetValue', val);
                              ref.read(transactionDetailsChangedProvider.notifier).state = true;
                            },
                            itemWidth: 100,
                            itemHeight: 45,
                            iconSize: 22,
                            spacing: 0,
                            selectedBg: theme.themeColor,
                            unselectedBg: theme.dashboardContainer,
                            selectedFg: theme.themeTextColor,
                            unselectedFg: theme.textColor.withAlpha((255 * 0.50).toInt()),
                          );
                        },
                      ),
                  ],
                ),
              ],

              if (widget.isMobile) ...[
                Row(
                  children: [
                    Expanded(
                      child: UserContactCustomTextField(
                        id: 99,
                        valueKey: 'name',
                        hintText: 'Title'.tr,
                        controller: ctrls.nameController,
                        validator: (v) => (v == null || v.isEmpty) ? "Title can't be empty".tr : null,
                        onChanged: (key, val) {
                          cache.addTransactionData(key, val);
                          _setChanged();
                        },
                      ),
                    ),
                  ],
                ),
                Divider(color: theme.textColor.withAlpha(120)),

                AgentTransactionFormCustomDropDown(
                  id: 7,
                  options: ['Cash'.tr, 'Transfer'.tr, 'Card'.tr],
                  hintText: 'Payment Method'.tr,
                  valueKey: 'payment_methods',
                  txId: widget.transaction?.id,
                  initialValue: widget.transaction?.paymentMethods,
                  onChanged: _setChanged,
                ),

                Row(
                  children: [
                    Expanded(
                      child: AddClientFormCustomDropDown(
                        id: 104,
                        hintText: 'Service Type'.tr,
                        valueKey: 'service_type',
                        options: contactTypeState.contactServiceType.map((e) => e.displayLabel).toList(),
                        values: contactTypeState.contactServiceType.map((e) => e.idAsString).toList(),
                        onChangedExtra: (newValue, id, valueKey) {},
                      ),
                    ),
                  ],
                ),

                    Row(
                    children: [
                      Expanded(
                        child: AddClientFormCustomDropDown(
                          id: 2013,
                          hintText: 'Responsible Person'.tr,
                          valueKey: 'responsible_person',
                          initialValue: widget.transaction?.responsiblePersonId?.toString(), // ✅ NEW
                          options: contactTypeState.userModel?.companyMembers
                                  .map((m) => '${m.firstName} ${m.lastName}')
                                  .toList() ??
                              const [],
                          values: contactTypeState.userModel?.companyMembers
                                  .map((m) => m.id.toString())
                                  .toList() ??
                              const [],
                          onChangedExtra: (newValue, id, valueKey) {
                            // ✅ to jest prawdziwe źródło dla transakcji
                            ref
                                .read(agentTransactionCacheProvider.notifier)
                                .addTransactionData(valueKey, newValue);
                            ref.read(transactionDetailsChangedProvider.notifier).state = true;
                          },
                        ),
                      ),
                    ],
                  ),


                Divider(color: theme.textColor.withAlpha(120)),


                Row(
                  children: [
                    Expanded(child: commissionFieldWithUnit()),
                    percentToggle(),
                  ],
                ),

                
                    const SizedBox(width: 12),

                     Row(
                       children: [
                         // ✅ waluta znika gdy %
                         Expanded(
                           child: currencyDropdown(
                             txId: widget.transaction?.id,
                             initial: widget.transaction?.currency,
                           ),
                         ),
                         const SizedBox(width: 12),
                         ValueListenableBuilder<bool>(
                            valueListenable: ctrls.isCommissionNetValue,
                            builder: (context, isPercent, _) {
                              return SegmentedIconToggle<bool>(
                                options: [
                                  ToggleOption<bool>(
                                    value: false,
                                    label: 'net_amount_label'.tr,
                                    iconBuilder: ({Color? color}) => Text('netto_label'.tr, style: TextStyle(color: color)),
                                  ),
                                  ToggleOption<bool>(
                                    value: true,
                                    label: 'gross_amount_label'.tr,
                                    iconBuilder: ({Color? color}) => Text('brutto_label'.tr, style: TextStyle(color: color)),
                                  ),
                                ],
                                selected: isPercent,
                                onChanged: (val) {
                                  ctrls.isCommissionNetValue.value = val;
                                  ref.read(agentTransactionCacheProvider.notifier)
                                    .addTransactionData('isCommissionNetValue', val);
                                  ref.read(transactionDetailsChangedProvider.notifier).state = true;
                                },
                                itemWidth: 80,
                                itemHeight: 45,
                                iconSize: 20,
                                spacing: 0,
                                selectedBg: theme.themeColor,
                                unselectedBg: theme.dashboardContainer,
                                selectedFg: theme.themeTextColor,
                                unselectedFg: theme.textColor.withAlpha((255 * 0.50).toInt()),
                              );
                            },
                          ),
                       ],
                     ),
              ],
            ],
          ),
        ),

        if (ref.watch(transactionDetailsChangedProvider)) ...[
          const SizedBox(height: 20),
          _SubmitBar(
            onSubmit: () async {
              final isNewTransaction = (widget.transaction?.id ?? 0) == 0;
              final txId = widget.transaction?.id;
              final nav = ref.read(navigationService);

              if (isNewTransaction) {
                try {
                  final created = await createTransactionFromUI(
                      ref: ref,
                      tx: widget.transaction,
                      dropdownScopeKey: _dropdownScope,
                    );
                  ref.read(transactionDetailsChangedProvider.notifier).state = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Text('${'transaction_created_message'.tr} #${created.id}'),
                          ElevatedButton(
                            onPressed: () => nav.pushNamedScreen(
                              '/pro/draft/contact/${created.client.id}/transakcje/${created.id}',
                            ),
                            child: Text('go_to_transaction_button'.tr),
                          )
                        ],
                      ),
                    ),
                  );
                  nav.beamPop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${'failed_to_create_transaction'.tr} $e')),
                  );
                }
              } else {
                if (txId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('missing_transaction_id'.tr)),
                  );
                  return;
                }
                try {
                  await submitTransactionDetails(
                    ref: ref,
                    transactionId: txId,
                    clientId: widget.transaction?.client.id,
                    draftId: widget.transaction?.draft,
                    currentTx: widget.transaction,
                    dropdownScopeKey: _dropdownScope,
                  );
                  ref.read(transactionDetailsChangedProvider.notifier).state = false;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('changes_saved_message'.tr)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${'failed_to_save_changes'.tr} $e')),
                  );
                }
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(ThemeColors theme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.themeColor,
        borderRadius: const BorderRadius.only(topRight: Radius.circular(6), topLeft: Radius.circular(6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'transactions_title'.tr,
            style: TextStyle(
              color: theme.themeTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          if ((widget.transaction?.id ?? 0) == 0) AppIcons.iosArrowDown(color: theme.themeTextColor),
        ],
      ),
    );
  }

  Widget _buildSubmitBar(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: _SubmitBar(
        onSubmit: () async {
          final isNewTransaction = (widget.transaction?.id ?? 0) == 0;
          final txId = widget.transaction?.id;

          if (isNewTransaction) {
            try {
              final created = await createTransactionFromUI(
                ref: ref,
                tx: widget.transaction,
                dropdownScopeKey: _dropdownScope,
              );
              ref.read(transactionDetailsChangedProvider.notifier).state = false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${'transaction_created_message'.tr} #${created.id}')),
              );
              ref.read(navigationService).beamPop();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${'failed_to_create_transactions'.tr} $e')),
              );
            }
          } else {
            if (txId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('missing_transaction_id'.tr)),
              );
              return;
            }
            try {
              await submitTransactionDetails(
                ref: ref,
                transactionId: txId,
                clientId: widget.transaction?.client.id,
                draftId: widget.transaction?.draft,
                currentTx: widget.transaction,
                dropdownScopeKey: _dropdownScope,
              );
              ref.read(transactionDetailsChangedProvider.notifier).state = false;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('changes_saved_message'.tr)),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${'failed_to_save_note'.tr} $e')),
              );
            }
          }
        },
      ),
    );
  }
}

// --------------------------- Pasek z przyciskiem zapisu ---------------------------

class _SubmitBar extends ConsumerWidget {
  final Future<void> Function() onSubmit;
  const _SubmitBar({required this.onSubmit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onSubmit,
        child: Container(
          height: 50,
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: theme.themeColor,
          ),
          child: Center(
            child: Text(
              'submit_button'.tr,
              style: AppTextStyles.interBold.copyWith(color: theme.themeTextColor),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------- KLIENT: lista/wybór ---------------------------
// (TEN BLOK ZOSTAJE U CIEBIE BEZ ZMIAN – SKRÓCIŁEM, BO NIE DOTYCZY TEJ ZMIANY)
// ... wklej swój ClientListAddFormCrm dokładnie tak jak miałeś ...

// --------------------------- IO: PATCH (update) ---------------------------

String? _getScopedDropdownValue(
  WidgetRef ref, {
  required int id,
  required String valueKey,
  String? scopeKey,
}) {
  if (scopeKey == null || scopeKey.trim().isEmpty) return null;

  final stateMap = ref.read(sellOfferDropDownProvider);
  final storageKey = DropdownNotifierUserContact.keyOf(id, valueKey, scopeKey);
  final raw = stateMap[storageKey]?.selectedValue;

  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  return trimmed;
}

Future<void> submitTransactionDetails({
  required WidgetRef ref,
  required int transactionId,
  required int? clientId,
  int? draftId,
  AgentTransactionModel? currentTx,
  String? dropdownScopeKey,
}) async {
  const allowedTxKeys = <String>{
    'name',
    'amount',
    'commission',
    'currency',
    'payment_methods',
    'isCommisssionPercentage',
    'isCommissionNetValue',
    'transaction_type',
    'status',
    'responsible_person',
  };

  final cache = Map<String, dynamic>.from(ref.read(agentTransactionCacheProvider));
  final ctrls = ref.read(transactionControllersProvider);
  final ddMap = ref.read(agentTransactionDropDownProvider);

  final txBody = <String, dynamic>{};

  void putIfHas(Map<String, dynamic> map, String key, Object? value) {
    if (!allowedTxKeys.contains(key) || value == null) return;

    if (key == 'responsible_person') {
      if (value is num) {
        map[key] = value.toInt();
        return;
      }

      final s = value.toString().trim();
      if (s.isEmpty) return;

      map[key] = int.tryParse(s) ?? s;
      return;
    }

    if (value is String) {
      final s = value.trim();
      if (s.isNotEmpty) map[key] = s;
    } else if (value is bool) {
      map[key] = value;
    } else if (value is num) {
      map[key] = value;
    } else {
      final s = value.toString().trim();
      if (s.isNotEmpty) map[key] = s;
    }
  }

  final scopedResponsiblePerson = _getScopedDropdownValue(
    ref,
    id: 2013,
    valueKey: 'responsible_person',
    scopeKey: dropdownScopeKey,
  );

  // 1. Najświeższe dane z kontrolerów
  putIfHas(txBody, 'name', ctrls.nameController.text);
  putIfHas(txBody, 'amount', ctrls.amountController.text);
  putIfHas(txBody, 'commission', ctrls.commissionController.text);
  putIfHas(txBody, 'isCommisssionPercentage', ctrls.isCommisssionPercentage.value);
  putIfHas(txBody, 'isCommissionNetValue', ctrls.isCommissionNetValue.value);

  // 2. Dropdowny transakcyjne
  for (final d in ddMap.values) {
    putIfHas(txBody, d.valueKey, d.selectedValue);
  }

  // 3. Scoped responsible person z konkretnego formularza
  putIfHas(txBody, 'responsible_person', scopedResponsiblePerson);

  // 4. Cache jako fallback, ale nadal ważniejszy niż currentTx
  for (final key in const [
    'name',
    'amount',
    'commission',
    'isCommisssionPercentage',
    'isCommissionNetValue',
    'currency',
    'payment_methods',
    'transaction_type',
    'status',
    'responsible_person',
  ]) {
    if (!txBody.containsKey(key)) {
      putIfHas(txBody, key, cache[key]);
    }
  }

  // 5. currentTx tylko jako ostateczny fallback
  if (!txBody.containsKey('transaction_type')) {
    putIfHas(txBody, 'transaction_type', currentTx?.transactionType);
  }
  if (!txBody.containsKey('status')) {
    putIfHas(txBody, 'status', currentTx?.status);
  }
  if (!txBody.containsKey('responsible_person')) {
    putIfHas(txBody, 'responsible_person', currentTx?.responsiblePersonId);
  }
  if (!txBody.containsKey('payment_methods')) {
    putIfHas(txBody, 'payment_methods', currentTx?.paymentMethods);
  }
  if (!txBody.containsKey('currency')) {
    putIfHas(txBody, 'currency', currentTx?.currency);
  }

  final isPercent = txBody['isCommisssionPercentage'] == true;
  if (isPercent) {
    txBody.remove('currency');
  }

  if (txBody.isEmpty && clientId == null && (draftId == null || draftId == 0)) {
    return;
  }

  final payload = <String, dynamic>{
    'transaction': txBody,
    if (draftId != null && draftId != 0) 'draft': draftId,
    if (clientId != null && clientId != 0) 'client': clientId,
  };

  final url = URLs.updateRevenuesCrm(transactionId.toString());
  final resp = await ApiServices.patch(url, hasToken: true, data: payload);
  final sc = resp?.statusCode ?? 0;
  if (resp == null || sc >= 300) {
    throw Exception('HTTP $sc');
  }

  await ref.read(transactionProvider.notifier).applyPartialUpdateLocally(transactionId, txBody);
  if (clientId != null) {
    ref.read(transactionListProvider(clientId).notifier).updatePartialLocal(transactionId, txBody);
  }
}
// --------------------------- IO: CREATE (POST) ---------------------------

Map<String, dynamic> _unwrapTransactionEnvelope(Map<String, dynamic> json) {
  final tx = Map<String, dynamic>.from(
    (json['transaction'] as Map?)?.map((k, v) => MapEntry(k as String, v)) ?? const {},
  );

  if (tx.isEmpty) return json;

  final clientFromEnvelope = json['client'];
  if (clientFromEnvelope != null) {
    tx['client'] = clientFromEnvelope;
  }

  if (tx['draft'] == null && json['draft'] != null) {
    final d = json['draft'];
    if (d is Map && d['id'] != null) {
      tx['draft'] = d['id'];
    } else if (d is int) {
      tx['draft'] = d;
    }
  }

  return tx;
}


Future<AgentTransactionModel> createTransactionFromUI({
  required WidgetRef ref,
  required AgentTransactionModel? tx,
  String? dropdownScopeKey,
}) async {
  final payload = _buildCreatePayloadFromUI(
    ref,
    tx: tx,
    dropdownScopeKey: dropdownScopeKey,
  );

  final url = URLs.estateAgentAddSellOffer;
  final resp = await ApiServices.post(url, hasToken: true, data: payload);
  final sc = resp?.statusCode ?? 0;
  if (resp == null || sc >= 300) {
    throw Exception('HTTP $sc (create)');
  }

  final data = resp.data as Map<String, dynamic>;
  final created = AgentTransactionModel.fromJson(_unwrapTransactionEnvelope(data));
  return created;
}

Map<String, dynamic> _buildCreatePayloadFromUI(
  WidgetRef ref, {
  required AgentTransactionModel? tx,
  String? dropdownScopeKey,
}) {
  const allowedTxKeys = <String>{
    'name',
    'amount',
    'commission',
    'currency',
    'payment_methods',
    'transaction_type',
    'isCommisssionPercentage',
    'isCommissionNetValue',
    'status',
    'is_seller',
    'responsible_person',
  };

  final cache = Map<String, dynamic>.from(ref.read(agentTransactionCacheProvider));
  final ctrls = ref.read(transactionControllersProvider);
  final ddMap = ref.read(agentTransactionDropDownProvider);

  final txBody = <String, dynamic>{};

  void putIfHas(String key, Object? value) {
    if (!allowedTxKeys.contains(key) || value == null) return;

    if (key == 'responsible_person') {
      if (value is num) {
        txBody[key] = value.toInt();
        return;
      }

      final s = value.toString().trim();
      if (s.isEmpty) return;

      txBody[key] = int.tryParse(s) ?? s;
      return;
    }

    if (value is String) {
      final s = value.trim();
      if (s.isNotEmpty) txBody[key] = s;
    } else if (value is bool) {
      txBody[key] = value;
    } else if (value is num) {
      txBody[key] = value;
    } else {
      final s = value.toString().trim();
      if (s.isNotEmpty) txBody[key] = s;
    }
  }

  final scopedResponsiblePerson = _getScopedDropdownValue(
    ref,
    id: 2013,
    valueKey: 'responsible_person',
    scopeKey: dropdownScopeKey,
  );

  // 1. Kontrolery
  putIfHas('name', ctrls.nameController.text);
  putIfHas('amount', ctrls.amountController.text);
  putIfHas('commission', ctrls.commissionController.text);
  putIfHas('isCommisssionPercentage', ctrls.isCommisssionPercentage.value);
  putIfHas('isCommissionNetValue', ctrls.isCommissionNetValue.value);
  putIfHas('is_seller', true);

  // 2. Dropdowny transakcyjne
  for (final d in ddMap.values) {
    putIfHas(d.valueKey, d.selectedValue);
  }

  // 3. Scoped responsible person z konkretnego formularza
  putIfHas('responsible_person', scopedResponsiblePerson);

  // 4. Cache
  for (final k in const [
    'name',
    'amount',
    'commission',
    'currency',
    'payment_methods',
    'isCommisssionPercentage',
    'isCommissionNetValue',
    'transaction_type',
    'status',
    'responsible_person',
  ]) {
    if (!txBody.containsKey(k)) {
      putIfHas(k, cache[k]);
    }
  }

  // 5. currentTx jako ostatni fallback
  if (!txBody.containsKey('transaction_type')) {
    putIfHas('transaction_type', tx?.transactionType);
  }
  if (!txBody.containsKey('status')) {
    putIfHas('status', tx?.status);
  }
  if (!txBody.containsKey('responsible_person')) {
    putIfHas('responsible_person', tx?.responsiblePersonId);
  }

  final isPercent = txBody['isCommisssionPercentage'] == true;
  if (isPercent) {
    txBody.remove('currency');
  }

  final selected = ref.read(selectedClientProvider);
  final clientId = selected?.id ?? tx?.client?.id;
  final draftId = tx?.draft;

  final payload = <String, dynamic>{
    'transaction': txBody,
    if (clientId != null && clientId != 0) 'client': clientId,
    if (draftId != null && draftId != 0) 'draft': draftId,
  }..removeWhere((k, v) => v == null);

  return payload;
}




// --------------------------- KLIENT: lista/wybór ---------------------------

const defaultAvatarUrl = '$configUrl/media/avatars/avatar.jpg';

class ClientListAddFormCrm extends ConsumerStatefulWidget {
  final bool isAddInvoice;
  final UserContactModel? contact;
  final int? initialClientId;
  const ClientListAddFormCrm({super.key, this.isAddInvoice = false, this.contact, this.initialClientId});

  @override
  ConsumerState<ClientListAddFormCrm> createState() => _ClientListAppBarState();
}

class _ClientListAppBarState extends ConsumerState<ClientListAddFormCrm> {
  bool isExpanded = false;
  final TextEditingController searchController = TextEditingController();
  late final ScrollController _scrollController;

  UserContactModel? _normalizedContact(UserContactModel? c) {
    if (c == null) return null;
    final cid = c.id;
    if (cid == null || cid == 0) return null;
    return c;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final normalized = _normalizedContact(widget.contact);
      ref.read(selectedClientProvider.notifier).state = normalized;
    });
  }

  @override
  void didUpdateWidget(covariant ClientListAddFormCrm oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldNorm = _normalizedContact(oldWidget.contact);
    final newNorm = _normalizedContact(widget.contact);

    if (oldNorm?.id != newNorm?.id) {
      ref.read(selectedClientProvider.notifier).state = newNorm;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedClient = ref.watch(selectedClientProvider);
    final theme = ref.watch(themeColorsProvider);
    final canClear = _normalizedContact(widget.contact) == null;

    return Column(
      children: [
        if (selectedClient != null)
          GestureDetector(
            onTap: () {
              setState(() => isExpanded = !isExpanded);
              if (isExpanded) {
                ref.read(clientProvider.notifier).fetchClients(
                  searchQuery: searchController.text,
                );
              }
            },
            child: Container(
              height: 50,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.dashboardContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundImage: NetworkImage(selectedClient.avatar ?? defaultAvatarUrl),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${selectedClient.name} ${selectedClient.lastName ?? ''}',
                      style: AppTextStyles.interRegular14.copyWith(color: theme.textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (canClear)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref.read(selectedClientProvider.notifier).state = null;
                        searchController.clear();
                      },
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          )
        else
          GestureDetector(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: ClipRRect(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isExpanded ? 600 : 50,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: isExpanded
                          ? Column(
                              children: [
                                Focus(
                                  onFocusChange: (hasFocus) {
                                    if (!hasFocus) setState(() => isExpanded = false);
                                  },
                                  child: TextField(
                                    controller: searchController,
                                    onChanged: (value) {
                                      ref.read(clientProvider.notifier).fetchClients(searchQuery: value);
                                    },
                                    onSubmitted: (value) {
                                      ref.read(clientProvider.notifier).fetchClients(searchQuery: value);
                                      setState(() => isExpanded = false);
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'search_client_hint'.tr,
                                      hintStyle: TextStyle(color: theme.textColor, fontSize: 14),
                                      focusColor: theme.dashboardContainer,
                                      fillColor: theme.dashboardContainer,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                        borderSide: BorderSide(color: theme.bordercolor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: Color.fromRGBO(35, 35, 35, 1)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6.0),
                                        borderSide: const BorderSide(color: Color.fromRGBO(35, 35, 35, 1)),
                                      ),
                                    ),
                                    cursorColor: Colors.white,
                                  ),
                                ),
                                Expanded(child: clientList(context, ref)),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.search, color: Theme.of(context).iconTheme.color, size: 25),
                                  InkWell(
                                    onTap: () {
                                      if (widget.isAddInvoice) {
                                        setState(() => isExpanded = !isExpanded);
                                      } else {
                                        ref.read(showUserContactsProvider.notifier).state = true;
                                      }
                                    },
                                    child: Container(
                                      width: 140,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: theme.themeColor,
                                        borderRadius: const BorderRadius.all(Radius.circular(6)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add, color: theme.themeTextColor),
                                          Text(
                                            'New user'.tr,
                                            style: TextStyle(
                                              color: theme.themeTextColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget clientList(BuildContext context, WidgetRef ref) {
    final clientListAsyncValue = ref.watch(clientProvider);
    return clientListAsyncValue.when(
      data: (clients) {
        if (clients.isEmpty) return _buildNoClientsMessage(context, ref);
        return _buildClientList(context, ref, clients);
      },
      loading: () => _buildShimmerLoading(context, ref),
      error: (err, stack) => _buildShimmerLoading(context, ref, showErrorIcon: true),
    );
  }

  Widget _buildNoClientsMessage(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Container(
            height: 32,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: CustomBackgroundGradients.adGradient1(context, ref),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text('no_clients_available'.tr, style: AppTextStyles.interRegular12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientList(BuildContext context, WidgetRef ref, List<UserContactModel> clients) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        _scrollController.jumpTo(_scrollController.offset - details.delta.dx);
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.vertical,
        child: Column(
          children: clients.map((c) => _buildClientCard(context, ref, c)).toList(),
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, WidgetRef ref, UserContactModel client) {
    return InkWell(
      onTap: () {
        if (widget.isAddInvoice) {
          ref.read(revenueFormProvider.notifier).setClient(client.id);
          ref.read(selectedClientProvider.notifier).state = client;
        } else {
          ref.read(selectedClientProvider.notifier).state = client;
          ref.read(addClientFormProvider.notifier).setSelectedClientId(client.id);
        }
        setState(() => isExpanded = false);
      },
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: CustomBackgroundGradients.crmadgradient(context, ref),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundImage: NetworkImage(client.avatar ?? defaultAvatarUrl),
                radius: 20,
              ),
              const SizedBox(width: 12),
              Text(client.name, style: AppTextStyles.interRegular14.copyWith(color: Theme.of(context).iconTheme.color)),
              const SizedBox(width: 10),
              Text(client.lastName ?? '', style: AppTextStyles.interRegular14.copyWith(color: Theme.of(context).iconTheme.color)),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context, WidgetRef ref, {bool showErrorIcon = false}) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          10,
          (index) => Container(
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: CustomBackgroundGradients.crmadgradient(context, ref),
            ),
            child: Center(
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Stack(
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[800]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      if (showErrorIcon)
                        const Positioned(
                          left: 5, top: 5,
                          child: Icon(Icons.error, color: Colors.red, size: 15),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 160, height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
