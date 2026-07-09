import 'package:crm/crm/finance/providers/finance_filters_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

class FinanceFiltersPopup extends ConsumerStatefulWidget {
  final FinanceTxType type;
  const FinanceFiltersPopup({super.key, required this.type});

  @override
  ConsumerState<FinanceFiltersPopup> createState() => _FinanceFiltersPopupState();
}

class _FinanceFiltersPopupState extends ConsumerState<FinanceFiltersPopup> {
  late final TextEditingController _searchCtrl;
  late final TextEditingController _amountMinCtrl;
  late final TextEditingController _amountMaxCtrl;
  late final FocusNode _amountMinFocus;
  late final FocusNode _amountMaxFocus;

  late String _sort;
  bool? _paid;

  DateTime? _createdFrom;
  DateTime? _createdTo;

  List<String> _paymentMethods = [];
  List<String> _txTypes = [];

  String? _currency;

  @override
  void initState() {
    super.initState();
    final current = ref.read(financeFiltersProvider(widget.type));

    _searchCtrl = TextEditingController(text: current.search);
    _amountMinCtrl = TextEditingController(text: current.amountMin ?? '');
    _amountMaxCtrl = TextEditingController(text: current.amountMax ?? '');
    _amountMinFocus = FocusNode();
    _amountMaxFocus = FocusNode();

    _sort = current.sort;
    _paid = current.paid;
    _currency = current.currency;

    _paymentMethods = List<String>.from(current.paymentMethods);
    _txTypes = List<String>.from(current.transactionTypes);

    _createdFrom = current.createdFrom;
    _createdTo = current.createdTo;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amountMinCtrl.dispose();
    _amountMaxCtrl.dispose();
    _amountMinFocus.dispose();
    _amountMaxFocus.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.type) {
      case FinanceTxType.revenue:
        return 'Revenue filters'.tr;
      case FinanceTxType.expense:
        return 'Expenses filters'.tr;
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")}';
  }

  Future<DateTime?> _pickDate(
      BuildContext context,
      ThemeColors theme,
      DateTime? initial,
      ) async {
    final now = DateTime.now();
    final init = initial ?? now;

    final date = await showDatePicker(
      useRootNavigator: true,
      context: context,
      initialDate: DateTime(init.year, init.month, init.day),
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      confirmText: 'OK'.tr,
      cancelText: 'Cancel'.tr,
      helpText: 'Choose date'.tr,
      fieldHintText: 'dd.MM.yyyy'.tr,
      fieldLabelText: 'Enter date'.tr,
      builder: (context, child) {
        final base = Theme.of(context);
        final isDark = base.brightness == Brightness.dark;

        final scheme = (isDark
            ? const ColorScheme.dark()
            : const ColorScheme.light())
            .copyWith(
          primary: theme.themeColor,
          onPrimary: theme.themeTextColor,
          surface: theme.adPopBackground,
          onSurface: theme.textColor,
        );

        return Theme(
          data: base.copyWith(
            colorScheme: scheme,
            dialogTheme: DialogThemeData(
              backgroundColor: theme.adPopBackground,
              surfaceTintColor: Colors.transparent,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: theme.textFieldColor,
              hintStyle: TextStyle(color: theme.textColor.withOpacity(0.7)),
              labelStyle: TextStyle(color: theme.textColor),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: theme.themeColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: theme.themeColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: theme.themeColor, width: 2),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: theme.adPopBackground,
              headerBackgroundColor: theme.themeColor,
              headerForegroundColor: theme.themeTextColor,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? theme.themeTextColor
                    : theme.textColor;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? theme.themeColor
                    : Colors.transparent;
              }),
              todayBorder: BorderSide(color: theme.themeColor),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: theme.themeColor),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  void _toggleListItem(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final filters = ref.watch(financeFiltersProvider(widget.type));
    final notifier = ref.read(financeFiltersProvider(widget.type).notifier);

    // Example values — replace with API/config later
    final paymentMethodOptions = <String>['bank', 'card', 'cash', 'blik'];
    final currencyOptions = <String>['PLN', 'EUR', 'USD'];
    final txTypeOptions = <String>['sale', 'rent', 'commission', 'service', 'other'];

    final sortOptions = <String, String>{
      'date_create_desc': 'Newest first'.tr,
      'date_create_asc': 'Oldest first'.tr,
      'amount_desc': 'Amount: high → low'.tr,
      'amount_asc': 'Amount: low → high'.tr,
      'date_update_desc': 'Recently updated'.tr,
      'payment_date_desc': 'Payment date: newest'.tr,
    };

    Widget sectionTitle(String title) {
      return Text(
        title,
        style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 14),
      );
    }

    ChoiceChip chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return ChoiceChip(
        label: Text(label, style: TextStyle(color: selected ? theme.themeTextColor : theme.textColor)),
        selected: selected,
        checkmarkColor: theme.themeTextColor,
        selectedColor: theme.themeColor,
        backgroundColor: theme.dashboardContainer,
        onSelected: (_) => onTap(),
      );
    }

    FilterChip fchip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return FilterChip(
        label: Text(label, style: TextStyle(color: selected ? theme.themeTextColor : theme.textColor)),
        selected: selected,
        selectedColor: theme.themeColor,
        backgroundColor: theme.dashboardContainer,
        onSelected: (_) => onTap(),
      );
    }

    Widget dateBox({
      required String label,
      required DateTime? value,
      required Future<void> Function() onTap,
    }) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.textColor.withAlpha((255 * .8).toInt()),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_fmt(value), style: TextStyle(color: theme.textColor)),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            color: theme.adPopBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _title,
                            style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: theme.textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ✅ SEARCH (CoreTextField)
                    sectionTitle('Search'.tr),
                    const SizedBox(height: 8),
                    CoreTextField(
                      label: 'Szukaj'.tr,
                      hintText: 'Search by title / note / invoice...'.tr,
                      controller: _searchCtrl,
                      fillColor: theme.dashboardContainer,
                      prefixIcon:  Icon(Icons.search, size: 18,color: theme.textColor),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon:  Icon(Icons.clear, size: 18,color: theme.textColor,),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // PAID
                    sectionTitle('Paid'.tr),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        chip(
                          label: 'Any'.tr,
                          selected: _paid == null,
                          onTap: () => setState(() => _paid = null),
                        ),
                        chip(
                          label: 'Yes'.tr,
                          selected: _paid == true,
                          onTap: () => setState(() => _paid = true),
                        ),
                        chip(
                          label: 'No'.tr,
                          selected: _paid == false,
                          onTap: () => setState(() => _paid = false),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // CURRENCY
                    sectionTitle('Waluta'.tr),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        chip(
                          label: 'Any'.tr,
                          selected: _currency == null,
                          onTap: () => setState(() => _currency = null),
                        ),
                        ...currencyOptions.map((c) {
                          return chip(
                            label: c,
                            selected: _currency == c,
                            onTap: () => setState(() => _currency = c),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // PAYMENT METHODS
                    sectionTitle('Payment methods'.tr),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        chip(
                          label: 'Any'.tr,
                          selected: _paymentMethods.isEmpty,
                          onTap: () => setState(() => _paymentMethods = []),
                        ),
                        ...paymentMethodOptions.map((pm) {
                          return fchip(
                            label: pm.tr,
                            selected: _paymentMethods.contains(pm),
                            onTap: () => _toggleListItem(_paymentMethods, pm),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // TRANSACTION TYPE
                    sectionTitle('Transaction type'.tr),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        chip(
                          label: 'Any'.tr,
                          selected: _txTypes.isEmpty,
                          onTap: () => setState(() => _txTypes = []),
                        ),
                        ...txTypeOptions.map((t) {
                          return fchip(
                            label: t.tr,
                            selected: _txTypes.contains(t),
                            onTap: () => _toggleListItem(_txTypes, t),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ✅ AMOUNT RANGE (CoreTextField)
                    sectionTitle('Amount range'.tr),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CoreTextField(
                            label: 'Min'.tr,
                            hintText: 'Min'.tr,
                            controller: _amountMinCtrl,
                            fillColor: theme.dashboardContainer,
                            focusNode: _amountMinFocus,
                            nextFocusNode: _amountMaxFocus,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CoreTextField(
                            label: 'Max'.tr,
                            hintText: 'Max'.tr,
                            controller: _amountMaxCtrl,
                            fillColor: theme.dashboardContainer,
                            focusNode: _amountMaxFocus,
                            nextFocusNode: null,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // CREATED DATE RANGE
                    sectionTitle('Created date range'.tr),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        dateBox(
                          label: 'From'.tr,
                          value: _createdFrom,
                          onTap: () async {
                            final d = await _pickDate(context, theme, _createdFrom);
                            if (d == null) return;
                            setState(() => _createdFrom = d);
                          },
                        ),
                        const SizedBox(width: 10),
                        dateBox(
                          label: 'to'.tr,
                          value: _createdTo,
                          onTap: () async {
                            final d = await _pickDate(context, theme, _createdTo);
                            if (d == null) return;
                            setState(() => _createdTo = d);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _createdFrom = null;
                        _createdTo = null;
                      }),
                      icon: Icon(Icons.clear, color: theme.textColor, size: 18),
                      label: Text('Clear range'.tr, style: TextStyle(color: theme.textColor)),
                    ),

                    const SizedBox(height: 16),

                    // ✅ SORT (CoreDropdown)
                    sectionTitle('Sortuj'.tr),
                    const SizedBox(height: 8),
                    CoreDropdown<String>(
                      label: 'Sort'.tr,
                      value: _sort,
                      options: sortOptions.keys.toList(),
                      fillColor: theme.dashboardContainer,
                      display: (v) => sortOptions[v] ?? v,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _sort = v);
                      },
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            notifier.reset();
                            _searchCtrl.text = '';
                            _amountMinCtrl.text = '';
                            _amountMaxCtrl.text = '';
                            setState(() {
                              final init = FinanceFilters.initial();
                              _sort = init.sort;
                              _paid = init.paid;
                              _currency = init.currency;
                              _paymentMethods = List<String>.from(init.paymentMethods);
                              _txTypes = List<String>.from(init.transactionTypes);
                              _createdFrom = init.createdFrom;
                              _createdTo = init.createdTo;
                            });
                          },
                          icon: Icon(Icons.refresh, color: theme.textColor, size: 18),
                          label: Text('Reset'.tr, style: TextStyle(color: theme.textColor)),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textColor,
                            side: BorderSide(color: theme.textColor.withAlpha((255 * .18).toInt())),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Anuluj'.tr),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.themeColor,
                            foregroundColor: theme.themeTextColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            notifier.setSearch(_searchCtrl.text.trim());
                            notifier.setSort(_sort);

                            notifier.setPaid(_paid);
                            notifier.setCurrency(_currency);

                            notifier.setPaymentMethods(_paymentMethods);
                            notifier.setTransactionTypes(_txTypes);

                            final min = _amountMinCtrl.text.trim();
                            final max = _amountMaxCtrl.text.trim();
                            notifier.setAmountRange(
                              min.isEmpty ? null : min,
                              max.isEmpty ? null : max,
                            );

                            notifier.setCreatedRange(_createdFrom, _createdTo);
                            Navigator.of(context).pop();
                          },
                          child: Text('Zastosuj'.tr),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Opacity(
                      opacity: 0.75,
                      child: Text(
                        '${'Current'.tr}: search="${filters.search}", sort=${filters.sort}',
                        style: TextStyle(color: theme.textColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
