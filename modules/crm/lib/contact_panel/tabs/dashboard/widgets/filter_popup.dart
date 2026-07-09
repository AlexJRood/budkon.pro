// transaction_filters_popup.dart
import 'package:crm/contact_panel/tabs/dashboard/widgets/new_client_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

class TransactionFiltersPopup extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final DraggableScrollableController sheetController;

  const TransactionFiltersPopup({
    super.key,
    required this.scrollController,
    required this.sheetController,
  });

  @override
  ConsumerState<TransactionFiltersPopup> createState() =>
      _TransactionFiltersPopupState();
}

class _TransactionFiltersPopupState
    extends ConsumerState<TransactionFiltersPopup> {
  final _statusCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _paymentCtrl = TextEditingController();
  final _amountMinCtrl = TextEditingController();
  final _amountMaxCtrl = TextEditingController();

  final _statusFocus = FocusNode();
  final _typeFocus = FocusNode();
  final _paymentFocus = FocusNode();
  final _amountMinFocus = FocusNode();
  final _amountMaxFocus = FocusNode();

  DateTime? _from;
  DateTime? _to;
  String? _ordering;

  @override
  void initState() {
    super.initState();

    final s = ref.read(transactionFilterProviderClientPanel);
    _statusCtrl.text = s.status ?? '';
    _typeCtrl.text = s.type ?? '';
    _paymentCtrl.text = s.paymentMethod ?? '';
    _amountMinCtrl.text = s.amountMin?.toString() ?? '';
    _amountMaxCtrl.text = s.amountMax?.toString() ?? '';
    _from = s.dateFrom;
    _to = s.dateTo;
    _ordering = s.ordering;
  }

  @override
  void dispose() {
    _statusCtrl.dispose();
    _typeCtrl.dispose();
    _paymentCtrl.dispose();
    _amountMinCtrl.dispose();
    _amountMaxCtrl.dispose();

    _statusFocus.dispose();
    _typeFocus.dispose();
    _paymentFocus.dispose();
    _amountMinFocus.dispose();
    _amountMaxFocus.dispose();

    super.dispose();
  }

  String _fmt(DateTime? v) {
    if (v == null) return '';
    final mm = v.month.toString().padLeft(2, '0');
    final dd = v.day.toString().padLeft(2, '0');
    return "${v.year}-$mm-$dd";
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final theme = ref.read(themeColorsProvider);
    final now = DateTime.now();
    final initial = isFrom ? (_from ?? now) : (_to ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: theme.themeColor,
            onPrimary: theme.textColor,
            surface: theme.dashboardContainer,
            onSurface: theme.textColor,
            outline: theme.dashboardBoarder,
            primaryContainer: theme.dashboardContainer,
            onPrimaryContainer: theme.textColor,
          ),
          dividerColor: theme.dashboardBoarder,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: theme.textColor),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: theme.dashboardContainer,
            headerBackgroundColor: theme.themeColor,
            headerForegroundColor: theme.textColor,
            dayForegroundColor: WidgetStatePropertyAll(theme.textColor),
            weekdayStyle: TextStyle(color: theme.textColor),
            dayStyle: TextStyle(color: theme.textColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dashboardBoarder),
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: theme.dashboardContainer,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to != null && _to!.isBefore(_from!)) _to = _from;
      } else {
        _to = picked;
        if (_from != null && _to!.isBefore(_from!)) _from = _to;
      }
    });
  }

  void _apply() {
    final notifier = ref.read(transactionFilterProviderClientPanel.notifier);

    final min = double.tryParse(_amountMinCtrl.text.replaceAll(',', '.'));
    final max = double.tryParse(_amountMaxCtrl.text.replaceAll(',', '.'));

    notifier
      ..setStatus(
        _statusCtrl.text.trim().isEmpty ? null : _statusCtrl.text.trim(),
      )
      ..setType(_typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim())
      ..setPaymentMethod(
        _paymentCtrl.text.trim().isEmpty ? null : _paymentCtrl.text.trim(),
      )
      ..setDateRange(_from, _to)
      ..setAmountRange(min, max);

    Navigator.of(context).maybePop();
  }

  void _clear() {
    ref.read(transactionFilterProviderClientPanel.notifier).clear();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      color: theme.dashboardContainer,
      child: ListView(
        controller: widget.scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 160,
        ),
        children: [
          Row(
            children: [
              Text(
                'transaction_filters_title'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const Spacer(),
              CoreIconButton(
                icon: Icons.close,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: CoreTextField(
                  label: 'status_label'.tr,
                  controller: _statusCtrl,
                  hintText: 'status_label'.tr,
                  focusNode: _statusFocus,
                  nextFocusNode: _typeFocus,
                  sheetController: widget.sheetController,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CoreTextField(
                  label: 'transaction_type_label'.tr,
                  controller: _typeCtrl,
                  hintText:'transaction_type_label'.tr,
                  focusNode: _typeFocus,
                  nextFocusNode: _paymentFocus,
                  sheetController: widget.sheetController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          CoreTextField(
            label: 'payment_method_label'.tr,
            controller: _paymentCtrl,
            hintText: 'payment_method_label'.tr,
            focusNode: _paymentFocus,
            nextFocusNode: _amountMinFocus,
            sheetController: widget.sheetController,
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: CoreOutlinedButton(
                  onPressed: () => _pickDate(isFrom: true),
                  child: DateButtonContent(
                    label: 'from_date_label'.tr,
                    value: _fmt(_from),
                    icon: Icons.calendar_month,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CoreOutlinedButton(
                  onPressed: () => _pickDate(isFrom: false),
                  child: DateButtonContent(
                    label:'to_date_label'.tr,
                    value: _fmt(_to),
                    icon: Icons.calendar_month,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: CoreTextField(
                  label: 'amount_min_label'.tr,
                  controller: _amountMinCtrl,
                  hintText: 'amount_min_label'.tr,
                  focusNode: _amountMinFocus,
                  nextFocusNode: _amountMaxFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  sheetController: widget.sheetController,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CoreTextField(
                  label: 'amount_max_label'.tr,
                  controller: _amountMaxCtrl,
                  hintText: 'amount_max_label'.tr,
                  focusNode: _amountMaxFocus,
                  nextFocusNode: null,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  sheetController: widget.sheetController,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              CoreOutlinedButton(
                onPressed: _clear,
                child: Text('clear_button'.tr),
              ),
              const Spacer(),
              CoreFilledButton(
                onPressed: _apply,
                child: Text('apply_button'.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }
}