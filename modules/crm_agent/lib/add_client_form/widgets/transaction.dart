import 'package:crm/data/clients/client_selection_provider.dart';
import 'package:crm_agent/widget/pro_draft_detail_view_widget.dart';
import 'package:crm_agent/add_client_form/components/transaction/transaction_custom_drop_down.dart';
import 'package:crm_agent/add_client_form/components/usercontact/user_contact_custom_text_field.dart';
import 'package:crm_agent/add_client_form/controllers/transaction_controlers.dart';
import 'package:crm_agent/add_client_form/provider/buy_filter_provider.dart';
import 'package:crm_agent/add_client_form/provider/contact_type_provider.dart';
import 'package:crm_agent/add_client_form/provider/send_form_provider.dart';
import 'package:crm_agent/add_client_form/provider/sell_estate_data_provider.dart';
import 'package:crm_agent/add_client_form/provider/transaction_provider.dart';
import 'package:crm_agent/add_client_form/transaction_autotitle_settings_provider.dart';
import 'package:crm_agent/models/transaction/agent_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ NEW: input formatters
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/platform/api/toggle_button.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:core/theme/icons.dart';
import 'package:core/theme/text_field.dart';
import 'package:core/user/user/user_model.dart' show CompanyMemberModel;



final transactionChangedProvider = StateProvider<bool>((ref) => false);

class TransactionCardWidget extends ConsumerStatefulWidget {
  final bool isMobile;
  final AgentTransactionModel? transaction;
  final bool isClientPanel;

  const TransactionCardWidget({
    super.key,
    this.isMobile = false,
    this.isClientPanel = false,
    this.transaction,
  });

  @override
  ConsumerState<TransactionCardWidget> createState() => _TransactionCardWidgetState();
}

class _TransactionCardWidgetState extends ConsumerState<TransactionCardWidget> {
  bool _titleListenerAttached = false;

  @override
  void initState() {
    super.initState();
    getData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrls = ref.read(transactionControllersProvider);
      final cacheN = ref.read(agentTransactionCacheProvider.notifier);

      final tx = widget.transaction;
      if (tx != null) {
        // controllers
        ctrls.nameController.text = tx.name;
        ctrls.amountController.text = tx.amount;
        ctrls.commissionController.text = tx.commission;

        // toggles
        ctrls.isCommisssionPercentage.value = tx.isCommisssionPercentage;
        ctrls.isCommissionNetValue.value = tx.isCommissionNetValue;

        // cache -> used on submit
        cacheN.addTransactionData('name', tx.name);
        cacheN.addTransactionData('amount', tx.amount);
        cacheN.addTransactionData('commission', tx.commission);
        cacheN.addTransactionData('currency', tx.currency);
        cacheN.addTransactionData('payment_methods', tx.paymentMethods);

        cacheN.addTransactionData('isCommisssionPercentage', tx.isCommisssionPercentage);
        cacheN.addTransactionData('isCommissionNetValue', tx.isCommissionNetValue);

        // ✅ responsible person
        cacheN.addTransactionData('responsible_person', tx.responsiblePersonId);

        // editing existing -> manual title
        ref.read(transactionTitleManuallyEditedProvider.notifier).state = true;
      }

      _attachTitleManualEditListener();
      _applyAutoTitleAndDefaultsIfNeeded();

      ref.listen(selectedClientProvider, (_, __) {
        _applyAutoTitleAndDefaultsIfNeeded();
      });
    });
  }

  void getData() async {
    final provider = ref.read(contactTypeProvider);
    await Future.wait([
      provider.getContactType(ref),
      provider.getContactStatus(ref),
      provider.getContactServiceType(ref),
      provider.getUserDetails(ref),
    ]);
    provider.resetState();
  }

  // --------------------------- AUTO TITLE LOGIC ---------------------------

  void _attachTitleManualEditListener() {
    if (_titleListenerAttached) return;

    final ctrls = ref.read(transactionControllersProvider);

    ctrls.nameController.addListener(() {
      if (!mounted) return;
      final alreadyManual = ref.read(transactionTitleManuallyEditedProvider);
      if (!alreadyManual) {
        if (ctrls.nameController.text.trim().isNotEmpty) {
          ref.read(transactionTitleManuallyEditedProvider.notifier).state = true;
        }
      }
    });

    _titleListenerAttached = true;
  }

  TransactionKind _currentKind() {
    final selectedTab = ref.read(selectedTabProvider);
    if (selectedTab == 'SELL'.tr) return TransactionKind.sell;
    if (selectedTab == 'BUY'.tr) return TransactionKind.buy;
    return TransactionKind.sell;
  }

  String _safeStr(dynamic v) => (v == null) ? '' : v.toString();

  String _extractClientFirstName() {
    final c = ref.read(selectedClientProvider);
    if (c == null) return '';
    final v = (c.name ?? '');
    return _safeStr(v).trim();
  }

  String _extractClientLastName() {
    final c = ref.read(selectedClientProvider);
    if (c == null) return '';
    final v = (c.lastName ?? '');
    return _safeStr(v).trim();
  }

  Map<String, dynamic> _sellDraftMap() {
    final data = ref.read(sellOfferFilterCacheProvider);
    final draft = data['draft'];
    if (draft is Map<String, dynamic>) return draft;
    if (draft is Map) return Map<String, dynamic>.from(draft);
    return {};
  }

  Map<String, dynamic> _buySearchMap() {
    final data = ref.read(buyOfferFilterCacheProvider);
    final ss = data['saved_search'];
    if (ss is Map<String, dynamic>) return ss;
    if (ss is Map) return Map<String, dynamic>.from(ss);
    return {};
  }

  String _extractAddress(AddressPart part) {
    final kind = _currentKind();
    final map = kind == TransactionKind.sell ? _sellDraftMap() : _buySearchMap();

    final city = _safeStr(map['city']).trim();
    final street = _safeStr(map['street']).trim();
    final district = _safeStr(map['district']).trim();
    final state = _safeStr(map['state']).trim();
    final country = _safeStr(map['country']).trim();

    final full = [
      if (street.isNotEmpty) street,
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (country.isNotEmpty) country,
    ].join(', ');

    switch (part) {
      case AddressPart.none:
        return '';
      case AddressPart.city:
        return city;
      case AddressPart.street:
        return street;
      case AddressPart.cityStreet:
        final parts = <String>[];
        if (city.isNotEmpty) parts.add(city);
        if (street.isNotEmpty) parts.add(street);
        return parts.join(', ');
      case AddressPart.district:
        return district;
      case AddressPart.full:
        return full;
    }
  }

  String _buildAutoTitle(AutoTitleRule rule) {
    final first = _extractClientFirstName();
    final last = _extractClientLastName();
    final addr = rule.includeAddress ? _extractAddress(rule.addressPart) : '';

    String name;
    if (rule.nameOrder == NameOrder.firstLast) {
      name = [first, last].where((e) => e.trim().isNotEmpty).join(rule.partsSeparator);
    } else {
      name = [last, first].where((e) => e.trim().isNotEmpty).join(rule.partsSeparator);
    }

    String base;
    if (addr.trim().isNotEmpty && name.trim().isNotEmpty) {
      base = '$name${rule.nameAddressSeparator}$addr';
    } else {
      base = name.trim().isNotEmpty ? name : addr;
    }

    base = base.trim();

    if (rule.includePrefix && rule.prefixText.trim().isNotEmpty) {
      if (base.isEmpty) return rule.prefixText.trim();
      return '${rule.prefixText.trim()}${rule.partsSeparator}$base';
    }

    return base;
  }

  void _setTitleProgrammatically(String title) {
    final ctrls = ref.read(transactionControllersProvider);
    final cacheN = ref.read(agentTransactionCacheProvider.notifier);

    // preserve manual state
    final prevManual = ref.read(transactionTitleManuallyEditedProvider);
    ref.read(transactionTitleManuallyEditedProvider.notifier).state = prevManual;

    ctrls.nameController.value = ctrls.nameController.value.copyWith(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );

    cacheN.addTransactionData('name', title);
    ref.read(transactionChangedProvider.notifier).state = true;
    ref.read(transactionDetailsChangedProvider.notifier).state = true;
  }

  void _applyDefaults(TransactionDefaults defaults) {
    final cacheN = ref.read(agentTransactionCacheProvider.notifier);
    final ctrls = ref.read(transactionControllersProvider);

    cacheN.addTransactionData('currency', defaults.defaultCurrency);
    cacheN.addTransactionData('payment_methods', defaults.defaultPaymentMethod);

    final shouldBePercent = defaults.defaultCommissionType == CommissionDefaultType.percent;
    if (ctrls.isCommisssionPercentage.value != shouldBePercent) {
      ctrls.isCommisssionPercentage.value = shouldBePercent;
      cacheN.addTransactionData('isCommisssionPercentage', shouldBePercent);
    }

    if (defaults.isCommissionNetValue != null) {
      final shouldBeNet = defaults.isCommissionNetValue!;
      if (ctrls.isCommissionNetValue.value != shouldBeNet) {
        ctrls.isCommissionNetValue.value = shouldBeNet;
        cacheN.addTransactionData('isCommissionNetValue', shouldBeNet);
      }
    } else {
      cacheN.addTransactionData('isCommissionNetValue', ctrls.isCommissionNetValue.value);
    }
  }

  void _applyAutoTitleAndDefaultsIfNeeded({bool forceTitle = false}) {
    final selectedTab = ref.read(selectedTabProvider);
    if (selectedTab == 'VIEW'.tr) return;

    final kind = _currentKind();
    final settings = ref.read(transactionUiSettingsProvider);
    final rule = kind == TransactionKind.sell ? settings.sellAutoTitle : settings.buyAutoTitle;
    final defaults = kind == TransactionKind.sell ? settings.sellDefaults : settings.buyDefaults;

    _applyDefaults(defaults);

    if (!rule.enabled) return;

    final ctrls = ref.read(transactionControllersProvider);
    final manual = ref.read(transactionTitleManuallyEditedProvider);
    final current = ctrls.nameController.text.trim();

    if (forceTitle || !manual || current.isEmpty) {
      final autoTitle = _buildAutoTitle(rule);
      if (autoTitle.isNotEmpty && autoTitle != current) {
        ref.read(transactionTitleManuallyEditedProvider.notifier).state = false;
        _setTitleProgrammatically(autoTitle);
        ref.read(transactionTitleManuallyEditedProvider.notifier).state = false;
      }
    }
  }

  Future<void> _openSettingsDialog() async {
    final kind = _currentKind();
    await showDialog<void>(
      context: context,
      builder: (_) => _TransactionSettingsDialog(kind: kind),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyAutoTitleAndDefaultsIfNeeded(forceTitle: false);
    });
  }

  // --------------------------- COMMISSION ROW HELPERS ---------------------------

  String _resolveCommissionUnit({
    required bool isPercent,
    required String? selectedCurrency,
  }) {
    if (isPercent) return '%';
    return (selectedCurrency == null || selectedCurrency.trim().isEmpty) ? '' : selectedCurrency.trim();
  }

  String? _getSelectedCurrencyFromUi() {
    final cache = ref.read(agentTransactionCacheProvider);
    final fromCache = cache['currency'];
    if (fromCache is String && fromCache.trim().isNotEmpty) return fromCache.trim();

    final ddMap = ref.read(agentTransactionDropDownProvider);
    for (final d in ddMap.values) {
      if (d.valueKey == 'currency') {
        final v = d.selectedValue;
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }

    return widget.transaction?.currency;
  }

  void _onPercentToggleChanged(bool val) {
    final ctrls = ref.read(transactionControllersProvider);
    final cacheN = ref.read(agentTransactionCacheProvider.notifier);

    ctrls.isCommisssionPercentage.value = val;
    cacheN.addTransactionData('isCommisssionPercentage', val);

    if (val == true) {
      cacheN.addTransactionData('currency', null);
    }

    ref.read(transactionDetailsChangedProvider.notifier).state = true;
    ref.read(transactionChangedProvider.notifier).state = true;
  }

  // ✅ NEW: formatters for "55 000 000.00"
  List<TextInputFormatter> _moneyInputFormatters() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^[0-9., ]*$')),
      TextInputFormatter.withFunction((oldValue, newValue) {
        final t = newValue.text;
        final dots = '.'.allMatches(t).length;
        final commas = ','.allMatches(t).length;
        if (dots + commas > 1) return oldValue;
        return newValue;
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cacheN = ref.read(agentTransactionCacheProvider.notifier);
    final transactionControllers = ref.watch(transactionControllersProvider);
    final theme = ref.watch(themeColorsProvider);
    final ctrls = ref.watch(transactionControllersProvider);
    final contactTypeState = ref.watch(contactTypeProvider);
    final manualTitle = ref.watch(transactionTitleManuallyEditedProvider);

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
                  label: 'static_amount'.tr,
                  iconBuilder: ({Color? color}) => AppIcons.circularDollar(color: color),
                ),
                ToggleOption<bool>(
                  value: true,
                  label:'procent'.tr,
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
              unselectedFg: theme.textColor.withAlpha(125),
            );
          },
        ),
      );
    }

    Widget currencyDropdown() {
      return ValueListenableBuilder<bool>(
        valueListenable: ctrls.isCommisssionPercentage,
        builder: (context, isPercent, _) {
          if (isPercent) return const SizedBox.shrink();

          return SizedBox(
            width: 110,
            child: AgentTransactionFormCustomDropDown(
              options: const ['PLN', 'EUR', 'USD'],
              hintText: 'Currency'.tr,
              valueKey: 'currency',
              id: 8,
            ),
          );
        },
      );
    }

    Widget commissionFieldWithUnit() {
      return ValueListenableBuilder<bool>(
        valueListenable: ctrls.isCommisssionPercentage,
        builder: (context, isPercent, _) {
          final currency = _getSelectedCurrencyFromUi();
          final unit = _resolveCommissionUnit(isPercent: isPercent, selectedCurrency: currency);

          return UserContactCustomTextField(
            id: 28,
            valueKey: 'commission',
            hintText: 'Commission'.tr,
            controller: transactionControllers.commissionController,

            // ✅ formatting
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _moneyInputFormatters(),
            normalizeCommaToDot: true,
            formatThousands: true,
            thousandSeparator: ' ',

            inlineSuffixText: unit.isEmpty ? null : unit,

            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Commission can't be empty".tr;
              }
              return null;
            },
            onChanged: (valueKey, value) {
              cacheN.addTransactionData(valueKey, value);
              ref.read(transactionChangedProvider.notifier).state = true;
              ref.read(transactionDetailsChangedProvider.notifier).state = true;
            },
          );
        },
      );
    }

    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: theme.themeColor,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(6),
              topLeft: Radius.circular(6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TRANSACTIONS'.tr,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'transaction_settings'.tr,
                      onPressed: _openSettingsDialog,
                      icon: Icon(Icons.settings, color: theme.themeTextColor),
                    ),
                    AppIcons.iosArrowDown(color: AppColors.white),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.adPopBackground,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(6),
              topLeft: Radius.circular(6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 12,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: UserContactCustomTextField(
                        id: 99,
                        valueKey: 'title',
                        hintText: 'Title'.tr,
                        formatThousands: false,
                        controller: transactionControllers.nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Title can't be empty".tr;
                          }
                          return null;
                        },
                        onChanged: (valueKey, value) {
                          cacheN.addTransactionData('name', value);
                          ref.read(transactionChangedProvider.notifier).state = true;
                          ref.read(transactionDetailsChangedProvider.notifier).state = true;

                          if (!ref.read(transactionTitleManuallyEditedProvider)) {
                            ref.read(transactionTitleManuallyEditedProvider.notifier).state = true;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'reset_auto_title'.tr,
                      onPressed: () {
                        ref.read(transactionTitleManuallyEditedProvider.notifier).state = false;
                        _applyAutoTitleAndDefaultsIfNeeded(forceTitle: true);
                      },
                      icon: Icon(
                        Icons.auto_fix_high,
                        color: manualTitle ? theme.textColor.withAlpha(180) : theme.themeTextColor,
                      ),
                    ),
                  ],
                ),

                Divider(color: theme.textColor.withAlpha(120)),

                Row(
                  children: [
                    Expanded(
                      child: AgentTransactionFormCustomDropDown(
                          options: const ['Cash', 'Transfer', 'Card'],
                          translateLabels: true, // ✅ label tłumaczony, value stabilne
                          hintText: 'Payment Method'.tr,
                          valueKey: 'payment_methods',
                          id: 7,
                        ),
                    ),
                  ],
                ),

// TODO: finish flow

                // Row(
                //   children: [
                //     Expanded(
                //       child: AddClientFormCustomDropDown(
                //         id: 104,
                //         hintText: 'Service Type'.tr,
                //         valueKey: 'service_type',
                //         options: contactTypeState.contactServiceType.map((e) => e.displayLabel).toList(),
                //         values: contactTypeState.contactServiceType.map((e) => e.idAsString).toList(),
                //         onChangedExtra: (newValue, id, valueKey) {},
                //       ),
                //     ),
                //   ],
                // ),

                _ResponsiblePersonRow(
                  members: contactTypeState.userModel?.companyMembers ?? const [],
                  currentUserId: contactTypeState.userModel?.idInt.toString(),
                  initialValue: widget.transaction?.responsiblePersonId?.toString(),
                  onChanged: (memberId) {
                    cacheN.addTransactionData('responsible_person', memberId);
                    ref.read(transactionDetailsChangedProvider.notifier).state = true;
                    ref.read(transactionChangedProvider.notifier).state = true;
                  },
                ),


                Divider(color: theme.textColor.withAlpha(120)),

                if (widget.isMobile) ...[
                  Row(
                    children: [
                      percentToggle(),
                      const SizedBox(width: 12),
                      Expanded(child: commissionFieldWithUnit()),
                      const SizedBox(width: 12),
                      currencyDropdown(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: ctrls.isCommissionNetValue,
                    builder: (context, isNet, _) {
                      Widget _nettoBtn(bool isSelected) => Expanded(
                        child: InkWell(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                          onTap: () {
                            ctrls.isCommissionNetValue.value = true;
                            cacheN.addTransactionData('isCommissionNetValue', true);
                            ref.read(transactionDetailsChangedProvider.notifier).state = true;
                            ref.read(transactionChangedProvider.notifier).state = true;
                          },
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: isSelected ? theme.themeColor : theme.dashboardContainer,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                            ),
                            child: Center(
                              child: Text(
                                'netto'.tr,
                                style: TextStyle(
                                  color: isSelected ? theme.themeTextColor : theme.textColor.withAlpha(128),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                      Widget _bruttoBtn(bool isSelected) => Expanded(
                        child: InkWell(
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                          onTap: () {
                            ctrls.isCommissionNetValue.value = false;
                            cacheN.addTransactionData('isCommissionNetValue', false);
                            ref.read(transactionDetailsChangedProvider.notifier).state = true;
                            ref.read(transactionChangedProvider.notifier).state = true;
                          },
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: !isSelected ? theme.themeColor : theme.dashboardContainer,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                            ),
                            child: Center(
                              child: Text(
                                'brutto'.tr,
                                style: TextStyle(
                                  color: !isSelected ? theme.themeTextColor : theme.textColor.withAlpha(128),
                                  fontWeight: !isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                      return Row(
                        children: [
                          _nettoBtn(isNet),
                          _bruttoBtn(isNet),
                        ],
                      );
                    },
                  ),
                ] else
                  Row(
                    children: [
                      percentToggle(),
                      const SizedBox(width: 12),

                      Expanded(flex: 4, child: commissionFieldWithUnit()),
                      const SizedBox(width: 12),

                      currencyDropdown(),
                      const SizedBox(width: 12),

                      ValueListenableBuilder<bool>(
                        valueListenable: ctrls.isCommissionNetValue,
                        builder: (context, isNet, _) {
                          return SizedBox(
                            width: 200,
                            child: SegmentedIconToggle<bool>(
                              options: [
                                ToggleOption<bool>(
                                  value: true,
                                  label: 'Wartosc netto'.tr,
                                  iconBuilder: ({Color? color}) => Text('netto'.tr, style: TextStyle(color: color)),
                                ),
                                ToggleOption<bool>(
                                  value: false,
                                  label: 'Wartosc brutto'.tr,
                                  iconBuilder: ({Color? color}) => Text('brutto'.tr, style: TextStyle(color: color)),
                                ),
                              ],
                              selected: isNet,
                              onChanged: (val) {
                                ctrls.isCommissionNetValue.value = val;
                                cacheN.addTransactionData('isCommissionNetValue', val);
                                ref.read(transactionDetailsChangedProvider.notifier).state = true;
                                ref.read(transactionChangedProvider.notifier).state = true;
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

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        if (widget.isClientPanel)
          if (ref.watch(transactionChangedProvider)) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final draftId = widget.transaction?.draft;
                    await ref.read(addClientFormProvider.notifier).sellTransActionTest(ref, draftId: draftId);
                    ref.read(transactionChangedProvider.notifier).state = false;
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      height: 50,
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: theme.themeColor,
                      ),
                      child: Center(
                        child: Text(
                          'submit'.tr,
                          style: AppTextStyles.interBold.copyWith(color: theme.themeTextColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
      ],
    );
  }
}





class _ResponsiblePersonRow extends ConsumerStatefulWidget {
  final List<CompanyMemberModel> members;
  final String? currentUserId;
  final String? initialValue;
  final void Function(String memberId) onChanged;

  const _ResponsiblePersonRow({
    required this.members,
    required this.currentUserId,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  ConsumerState<_ResponsiblePersonRow> createState() => _ResponsiblePersonRowState();
}

class _ResponsiblePersonRowState extends ConsumerState<_ResponsiblePersonRow> {
  String? _selected;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.members.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyDefault());
    }
  }

  @override
  void didUpdateWidget(covariant _ResponsiblePersonRow old) {
    super.didUpdateWidget(old);
    if (!_initialized && widget.members.isNotEmpty && widget.currentUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyDefault();
      });
    }
  }

  void _applyDefault() {
    final ids = widget.members.map((m) => m.id.toString()).toSet();

    String? chosen;
    if (widget.initialValue != null && ids.contains(widget.initialValue)) {
      chosen = widget.initialValue;
    } else if (widget.currentUserId != null && ids.contains(widget.currentUserId)) {
      chosen = widget.currentUserId;
    } else if (widget.members.isNotEmpty) {
      chosen = widget.members.first.id.toString();
    }

    if (chosen != null && chosen != _selected) {
      setState(() => _selected = chosen);
      widget.onChanged(chosen!);
    }
    _initialized = true;
  }

  String _initials(CompanyMemberModel m) {
    final f = m.firstName.trim();
    final l = m.lastName.trim();
    if (f.isEmpty && l.isEmpty) return '?';
    return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final ids = widget.members.map((m) => m.id.toString()).toList();
    final effectiveSelected = ids.contains(_selected) ? _selected : null;
    final isMe = effectiveSelected != null && effectiveSelected == widget.currentUserId;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: effectiveSelected != null ? theme.textColor : theme.dashboardBoarder,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: effectiveSelected,
                hint: Text(
                  'Responsible Person'.tr,
                  style: TextStyle(color: theme.textColor, fontSize: 12),
                ),
                isExpanded: true,
                borderRadius: BorderRadius.circular(6),
                dropdownColor: theme.dashboardContainer,
                icon: AppIcons.iosArrowDown(color: theme.textColor),
                style: TextStyle(color: theme.textColor, fontSize: 14),
                items: widget.members.map((m) {
                  return DropdownMenuItem<String>(
                    value: m.id.toString(),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.themeColor.withAlpha(60),
                          backgroundImage: (m.avatar != null && m.avatar!.isNotEmpty)
                              ? NetworkImage(m.avatar!)
                              : null,
                          child: (m.avatar == null || m.avatar!.isEmpty)
                              ? Text(
                                  _initials(m),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.themeTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${m.firstName} ${m.lastName}'.trim(),
                          style: TextStyle(color: theme.textColor),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selected = v);
                  widget.onChanged(v);
                },
              ),
            ),
          ),
        ),
        if (!isMe && widget.currentUserId != null && ids.contains(widget.currentUserId)) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final me = widget.currentUserId!;
              setState(() => _selected = me);
              widget.onChanged(me);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.themeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.themeColor.withAlpha(120)),
              ),
              child: Text(
                'is_me'.tr,
                style: TextStyle(
                  color: theme.themeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TransactionSettingsDialog extends ConsumerStatefulWidget {
  final TransactionKind kind;
  const _TransactionSettingsDialog({required this.kind});

  @override
  ConsumerState<_TransactionSettingsDialog> createState() =>
      _TransactionSettingsDialogState();
}

class _TransactionSettingsDialogState
    extends ConsumerState<_TransactionSettingsDialog> {
  late AutoTitleRule _rule;
  late TransactionDefaults _defaults;

  final _prefixCtrl = TextEditingController();
  final _nameAddrSepCtrl = TextEditingController();
  final _partsSepCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(transactionUiSettingsProvider);

    _rule = widget.kind == TransactionKind.sell
        ? settings.sellAutoTitle
        : settings.buyAutoTitle;

    _defaults = widget.kind == TransactionKind.sell
        ? settings.sellDefaults
        : settings.buyDefaults;

    _prefixCtrl.text = _rule.prefixText;
    _nameAddrSepCtrl.text = _rule.nameAddressSeparator;
    _partsSepCtrl.text = _rule.partsSeparator;
  }

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _nameAddrSepCtrl.dispose();
    _partsSepCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final notifier = ref.read(transactionUiSettingsProvider.notifier);

    final updatedRule = _rule.copyWith(
      prefixText: _prefixCtrl.text,
      nameAddressSeparator: _nameAddrSepCtrl.text,
      partsSeparator: _partsSepCtrl.text,
    );

    notifier.updateRule(widget.kind, updatedRule);
    notifier.updateDefaults(widget.kind, _defaults);

    Navigator.pop(context);
  }

  Widget _sectionTitle(String text) {
    final theme = ref.watch(themeColorsProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: theme.textColor.withAlpha(220),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _coreSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.textColor.withAlpha((255 * 0.18).toInt())),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: theme.textColor, fontSize: 13),
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) => onChanged(v),
            activeColor: theme.themeColor,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final title = widget.kind == TransactionKind.sell ? 'SELL'.tr : 'BUY'.tr;

    // ✅ Stable values (no .tr in value!)
    const paymentValues = <String>['Cash', 'Transfer', 'Card'];
    const currencyValues = <String>['PLN', 'EUR', 'USD'];

    return AlertDialog(
      backgroundColor: theme.adPopBackground,
      title: Text(
        '${'transaction_settings'.tr}: $title',
        style: TextStyle(color: theme.textColor),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _sectionTitle('auto_title'.tr),

              _coreSwitchRow(
                label: 'enable_auto_title'.tr,
                value: _rule.enabled,
                onChanged: (v) => setState(() => _rule = _rule.copyWith(enabled: v)),
              ),
              const SizedBox(height: 10),

              _coreSwitchRow(
                label: 'include_prefix'.tr,
                value: _rule.includePrefix,
                onChanged: (v) => setState(() => _rule = _rule.copyWith(includePrefix: v)),
              ),
              const SizedBox(height: 10),

              CoreTextField(
                label: 'prefix_text'.tr,
                controller: _prefixCtrl,
                enabled: _rule.includePrefix,
              ),
              const SizedBox(height: 10),

              CoreDropdownFormField<NameOrder>(
                label: 'name_order'.tr,
                value: _rule.nameOrder,
                options: NameOrder.values,
                display: (v) => nameOrderLabel(v).tr,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _rule = _rule.copyWith(nameOrder: v));
                },
              ),
              const SizedBox(height: 10),

              _coreSwitchRow(
                label: 'include_address'.tr,
                value: _rule.includeAddress,
                onChanged: (v) => setState(() => _rule = _rule.copyWith(includeAddress: v)),
              ),
              const SizedBox(height: 10),

              CoreDropdownFormField<AddressPart>(
                label: 'address_part'.tr,
                value: _rule.addressPart,
                options: AddressPart.values,
                display: (v) => addressPartLabel(v).tr,
                enabled: _rule.includeAddress,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _rule = _rule.copyWith(addressPart: v));
                },
              ),
              const SizedBox(height: 10),

              CoreTextField(
                label: 'name_address_separator'.tr,
                controller: _nameAddrSepCtrl,
              ),
              const SizedBox(height: 10),

              CoreTextField(
                label: 'parts_separator'.tr,
                controller: _partsSepCtrl,
              ),

              const SizedBox(height: 18),
              Divider(color: theme.textColor.withAlpha(80)),
              const SizedBox(height: 12),

              _sectionTitle('defaults'.tr),

              CoreDropdownFormField<String>(
                label: 'default_currency'.tr,
                value: _defaults.defaultCurrency,
                options: currencyValues,
                display: (v) => v, // waluty bez tłumaczeń
                onChanged: (v) => setState(() => _defaults = _defaults.copyWith(defaultCurrency: v)),
              ),
              const SizedBox(height: 10),

              // ✅ value stable, label translated
              CoreDropdownFormField<String>(
                label: 'default_payment_method'.tr,
                value: paymentValues.contains(_defaults.defaultPaymentMethod)
                    ? _defaults.defaultPaymentMethod
                    : 'Transfer', // fallback
                options: paymentValues,
                display: (v) => v.tr,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _defaults = _defaults.copyWith(defaultPaymentMethod: v));
                },
              ),
              const SizedBox(height: 10),

              CoreDropdownFormField<CommissionDefaultType>(
                label: 'default_commission_type'.tr,
                value: _defaults.defaultCommissionType,
                options: CommissionDefaultType.values,
                display: (v) => commissionDefaultLabel(v).tr,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _defaults = _defaults.copyWith(defaultCommissionType: v));
                },
              ),
              const SizedBox(height: 10),

              // net/gross default (optional)
              CoreDropdownFormField<bool>(
                label: 'commission_value_type'.tr,
                value: _defaults.isCommissionNetValue,
                options: const [true, false],
                display: (v) => v ? 'netto'.tr : 'brutto'.tr,
                onChanged: (v) => setState(() => _defaults = _defaults.copyWith(isCommissionNetValue: v)),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: CoreOutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'.tr),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CoreFilledButton(
                onPressed: _save,
                child: Text('Save'.tr),
              ),
            ),
          ],
        ),
      ],
    );
  }
}