import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

Future<Map<String, dynamic>?> showManualSettlementLineDialog({
  required BuildContext context,
  String currency = 'PLN',
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ManualSettlementLineDialog(currency: currency),
  );
}

class _ManualSettlementLineDialog extends ConsumerStatefulWidget {
  final String currency;

  const _ManualSettlementLineDialog({required this.currency});

  @override
  ConsumerState<_ManualSettlementLineDialog> createState() =>
      _ManualSettlementLineDialogState();
}

class _ManualSettlementLineDialogState
    extends ConsumerState<_ManualSettlementLineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();

  String _direction = 'earning';
  String _lineType = 'adjustment';
  bool _employeeVisible = true;

  double get _parsedAmount =>
      double.tryParse(_amount.text.trim().replaceAll(',', '.')) ?? 0.0;

  bool get _isNegative => _direction == 'deduction';

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop({
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'amount': _parsedAmount,
      'direction': _direction,
      'line_type': _lineType,
      'is_employee_visible': _employeeVisible,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 680;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24,
        vertical: isCompact ? 12 : 24,
      ),
      backgroundColor: theme.dashboardContainer,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dashboardBoarder),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: screenSize.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              icon: Icons.playlist_add_circle_outlined,
              title: 'add_manual_settlement_line'.tr,
              subtitle: 'manual_settlement_line_dialog_hint'.tr,
              backgroundColor: theme.dashboardContainer,
              borderColor: theme.dashboardBoarder,
              textColor: theme.textColor,
              accentColor: theme.themeColor,
              onClose: () => Navigator.of(context).pop(),
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isCompact ? 16 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionPanel(
                        title: 'settlement_line_basic_information'.tr,
                        icon: Icons.description_outlined,
                        backgroundColor: theme.adPopBackground,
                        borderColor: theme.dashboardBoarder,
                        textColor: theme.textColor,
                        child: Column(
                          children: [
                            CoreTextFormField(
                              label: 'name'.tr,
                              controller: _title,
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icon(
                                Icons.edit_outlined,
                                color: theme.textColor.withAlpha(170),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'field_required'.tr
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'rule_direction'.tr,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final cards = [
                                  _DirectionOption(
                                    value: 'earning',
                                    icon: Icons.trending_up_rounded,
                                    title: 'rule_direction_earning'.tr,
                                    subtitle:
                                        'manual_direction_earning_hint'.tr,
                                  ),
                                  _DirectionOption(
                                    value: 'deduction',
                                    icon: Icons.trending_down_rounded,
                                    title: 'rule_direction_deduction'.tr,
                                    subtitle:
                                        'manual_direction_deduction_hint'.tr,
                                  ),
                                  _DirectionOption(
                                    value: 'reimbursement',
                                    icon: Icons.currency_exchange_outlined,
                                    title:
                                        'rule_direction_reimbursement'.tr,
                                    subtitle:
                                        'manual_direction_reimbursement_hint'
                                            .tr,
                                  ),
                                ];

                                if (constraints.maxWidth < 560) {
                                  return Column(
                                    children: [
                                      for (var index = 0;
                                          index < cards.length;
                                          index++) ...[
                                        _ChoiceCard(
                                          selected:
                                              _direction == cards[index].value,
                                          icon: cards[index].icon,
                                          title: cards[index].title,
                                          subtitle: cards[index].subtitle,
                                          accentColor: theme.themeColor,
                                          textColor: theme.textColor,
                                          backgroundColor:
                                              theme.dashboardContainer,
                                          borderColor: theme.dashboardBoarder,
                                          onTap: () => setState(
                                            () => _direction = cards[index].value,
                                          ),
                                        ),
                                        if (index < cards.length - 1)
                                          const SizedBox(height: 8),
                                      ],
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    for (var index = 0;
                                        index < cards.length;
                                        index++) ...[
                                      Expanded(
                                        child: _ChoiceCard(
                                          selected:
                                              _direction == cards[index].value,
                                          icon: cards[index].icon,
                                          title: cards[index].title,
                                          subtitle: cards[index].subtitle,
                                          accentColor: theme.themeColor,
                                          textColor: theme.textColor,
                                          backgroundColor:
                                              theme.dashboardContainer,
                                          borderColor: theme.dashboardBoarder,
                                          onTap: () => setState(
                                            () => _direction = cards[index].value,
                                          ),
                                        ),
                                      ),
                                      if (index < cards.length - 1)
                                        const SizedBox(width: 8),
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final fieldWidth = constraints.maxWidth >= 500
                                    ? (constraints.maxWidth - 12) / 2
                                    : constraints.maxWidth;

                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    SizedBox(
                                      width: fieldWidth,
                                      child: CoreDropdown<String>(
                                        label: 'settlement_line_type'.tr,
                                        value: _lineType,
                                        options: const [
                                          'bonus',
                                          'deduction',
                                          'reimbursement',
                                          'adjustment',
                                          'custom',
                                        ],
                                        display: (value) =>
                                            'settlement_line_type_$value'.tr,
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _lineType = value);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: fieldWidth,
                                      child: CoreTextFormField(
                                        label:
                                            '${'amount'.tr} (${widget.currency})',
                                        controller: _amount,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        textInputAction: TextInputAction.next,
                                        prefixIcon: Icon(
                                          Icons.payments_outlined,
                                          color:
                                              theme.textColor.withAlpha(170),
                                        ),
                                        suffixIcon: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Center(
                                            widthFactor: 1,
                                            child: Text(
                                              widget.currency,
                                              style: TextStyle(
                                                color: theme.textColor
                                                    .withAlpha(180),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*[.,]?\d{0,2}'),
                                          ),
                                        ],
                                        onChanged: (_) => setState(() {}),
                                        validator: (value) {
                                          final amount = double.tryParse(
                                            (value ?? '')
                                                .trim()
                                                .replaceAll(',', '.'),
                                          );
                                          return amount == null || amount <= 0
                                              ? 'invalid_amount'.tr
                                              : null;
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            CoreTextFormField(
                              label: 'description'.tr,
                              controller: _description,
                              minLines: 3,
                              maxLines: 5,
                              textInputAction: TextInputAction.newline,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(bottom: 50),
                                child: Icon(
                                  Icons.notes_outlined,
                                  color: theme.textColor.withAlpha(170),
                                ),
                              ),
                              hintText: 'manual_settlement_description_hint'.tr,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _VisibilityTile(
                        value: _employeeVisible,
                        title: 'visible_to_employee'.tr,
                        subtitle: _employeeVisible
                            ? 'visible_to_employee_enabled_hint'.tr
                            : 'visible_to_employee_disabled_hint'.tr,
                        icon: _employeeVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        backgroundColor: theme.adPopBackground,
                        borderColor: theme.dashboardBoarder,
                        textColor: theme.textColor,
                        accentColor: theme.themeColor,
                        onChanged: (value) =>
                            setState(() => _employeeVisible = value),
                      ),
                      const SizedBox(height: 14),
                      _AmountPreview(
                        title: 'settlement_preview'.tr,
                        label: 'settlement_effect'.tr,
                        value: _parsedAmount,
                        currency: widget.currency,
                        negative: _isNegative,
                        backgroundColor: theme.adPopBackground,
                        borderColor: theme.dashboardBoarder,
                        textColor: theme.textColor,
                        accentColor: theme.themeColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _DialogFooter(
              backgroundColor: theme.dashboardContainer,
              borderColor: theme.dashboardBoarder,
              cancelLabel: 'cancel'.tr,
              confirmLabel: 'add'.tr,
              confirmIcon: Icons.add_rounded,
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>?> showRegisterPaymentDialog({
  required BuildContext context,
  required double outstandingAmount,
  required String currency,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RegisterPaymentDialog(
      outstandingAmount: outstandingAmount,
      currency: currency,
    ),
  );
}

class _RegisterPaymentDialog extends ConsumerStatefulWidget {
  final double outstandingAmount;
  final String currency;

  const _RegisterPaymentDialog({
    required this.outstandingAmount,
    required this.currency,
  });

  @override
  ConsumerState<_RegisterPaymentDialog> createState() =>
      _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState
    extends ConsumerState<_RegisterPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  final _reference = TextEditingController();
  final _note = TextEditingController();

  String _paymentMethod = 'bank_transfer';

  double get _parsedAmount =>
      double.tryParse(_amount.text.trim().replaceAll(',', '.')) ?? 0.0;

  double get _remainingAmount {
    final value = widget.outstandingAmount - _parsedAmount;
    return value < 0 ? 0 : value;
  }

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.outstandingAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  void _setAmount(double multiplier) {
    _amount.text = (widget.outstandingAmount * multiplier).toStringAsFixed(2);
    _amount.selection = TextSelection.collapsed(offset: _amount.text.length);
    setState(() {});
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop({
      'amount': _parsedAmount,
      'payment_method': _paymentMethod,
      'reference': _reference.text.trim(),
      'note': _note.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 620;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24,
        vertical: isCompact ? 12 : 24,
      ),
      backgroundColor: theme.dashboardContainer,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dashboardBoarder),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: screenSize.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              icon: Icons.price_check_outlined,
              title: 'register_payment'.tr,
              subtitle: 'register_payment_dialog_hint'.tr,
              backgroundColor: theme.dashboardContainer,
              borderColor: theme.dashboardBoarder,
              textColor: theme.textColor,
              accentColor: theme.themeColor,
              onClose: () => Navigator.of(context).pop(),
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isCompact ? 16 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _OutstandingBanner(
                        amount: widget.outstandingAmount,
                        currency: widget.currency,
                        borderColor: theme.dashboardBoarder,
                        textColor: theme.textColor,
                        accentColor: theme.themeColor,
                      ),
                      const SizedBox(height: 14),
                      _SectionPanel(
                        title: 'payment_details'.tr,
                        icon: Icons.account_balance_wallet_outlined,
                        backgroundColor: theme.adPopBackground,
                        borderColor: theme.dashboardBoarder,
                        textColor: theme.textColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CoreTextFormField(
                              label:
                                  '${'amount'.tr} (${widget.currency})',
                              controller: _amount,
                              autofocus: true,
                              keyboardType: const TextInputType
                                  .numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icon(
                                Icons.payments_outlined,
                                color: theme.textColor.withAlpha(170),
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Center(
                                  widthFactor: 1,
                                  child: Text(
                                    widget.currency,
                                    style: TextStyle(
                                      color: theme.textColor.withAlpha(180),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*[.,]?\d{0,2}'),
                                ),
                              ],
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                final amount = double.tryParse(
                                  (value ?? '')
                                      .trim()
                                      .replaceAll(',', '.'),
                                );
                                if (amount == null || amount <= 0) {
                                  return 'invalid_amount'.tr;
                                }
                                if (amount >
                                    widget.outstandingAmount + 0.0001) {
                                  return 'amount_exceeds_outstanding'.tr;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'quick_amount'.tr,
                              style: TextStyle(
                                color: theme.textColor.withAlpha(185),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _QuickAmountButton(
                                  label: '25%',
                                  onPressed: () => _setAmount(0.25),
                                  backgroundColor: theme.dashboardContainer,
                                  borderColor: theme.dashboardBoarder,
                                  textColor: theme.textColor,
                                  accentColor: theme.themeColor,
                                ),
                                _QuickAmountButton(
                                  label: '50%',
                                  onPressed: () => _setAmount(0.50),
                                  backgroundColor: theme.dashboardContainer,
                                  borderColor: theme.dashboardBoarder,
                                  textColor: theme.textColor,
                                  accentColor: theme.themeColor,
                                ),
                                _QuickAmountButton(
                                  label: '75%',
                                  onPressed: () => _setAmount(0.75),
                                  backgroundColor: theme.dashboardContainer,
                                  borderColor: theme.dashboardBoarder,
                                  textColor: theme.textColor,
                                  accentColor: theme.themeColor,
                                ),
                                _QuickAmountButton(
                                  label: 'full_amount'.tr,
                                  onPressed: () => _setAmount(1),
                                  backgroundColor: theme.dashboardContainer,
                                  borderColor: theme.dashboardBoarder,
                                  textColor: theme.textColor,
                                  accentColor: theme.themeColor,
                                  highlighted: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            CoreDropdown<String>(
                              label: 'payment_method'.tr,
                              value: _paymentMethod,
                              options: const [
                                'bank_transfer',
                                'cash',
                                'card',
                                'other',
                              ],
                              display: (value) =>
                                  'payment_method_$value'.tr,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _paymentMethod = value);
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            CoreTextFormField(
                              label: 'payment_reference'.tr,
                              controller: _reference,
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icon(
                                Icons.tag_outlined,
                                color: theme.textColor.withAlpha(170),
                              ),
                              hintText: 'payment_reference_hint'.tr,
                            ),
                            const SizedBox(height: 14),
                            CoreTextFormField(
                              label: 'note'.tr,
                              controller: _note,
                              minLines: 3,
                              maxLines: 5,
                              textInputAction: TextInputAction.newline,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(bottom: 50),
                                child: Icon(
                                  Icons.notes_outlined,
                                  color: theme.textColor.withAlpha(170),
                                ),
                              ),
                              hintText: 'payment_note_hint'.tr,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PaymentPreview(
                        paymentAmount: _parsedAmount,
                        remainingAmount: _remainingAmount,
                        currency: widget.currency,
                        backgroundColor: theme.adPopBackground,
                        borderColor: theme.dashboardBoarder,
                        textColor: theme.textColor,
                        accentColor: theme.themeColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _DialogFooter(
              backgroundColor: theme.dashboardContainer,
              borderColor: theme.dashboardBoarder,
              cancelLabel: 'cancel'.tr,
              confirmLabel: 'confirm_payment'.tr,
              confirmIcon: Icons.check_rounded,
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.accentColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withAlpha(65)),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withAlpha(160),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CoreIconButton(
            icon: Icons.close_rounded,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final String cancelLabel;
  final String confirmLabel;
  final IconData confirmIcon;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _DialogFooter({
    required this.backgroundColor,
    required this.borderColor,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmIcon,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CoreOutlinedButton(
            onPressed: onCancel,
            child: Text(cancelLabel),
          ),
          const SizedBox(width: 10),
          CoreFilledButton(
            onPressed: onConfirm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(confirmIcon, size: 18),
                const SizedBox(width: 7),
                Text(confirmLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _SectionPanel({
    required this.title,
    required this.icon,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: textColor.withAlpha(190)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DirectionOption {
  final String value;
  final IconData icon;
  final String title;
  final String subtitle;

  const _DirectionOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _ChoiceCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accentColor.withAlpha(22) : backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accentColor : borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? accentColor
                        : textColor.withAlpha(170),
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                    color: selected
                        ? accentColor
                        : textColor.withAlpha(90),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor.withAlpha(145),
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityTile extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _VisibilityTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: value
                      ? accentColor.withAlpha(24)
                      : textColor.withAlpha(12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: value ? accentColor : textColor.withAlpha(150),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withAlpha(150),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch.adaptive(
                value: value,
                activeColor: accentColor,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountPreview extends StatelessWidget {
  final String title;
  final String label;
  final double value;
  final String currency;
  final bool negative;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;

  const _AmountPreview({
    required this.title,
    required this.label,
    required this.value,
    required this.currency,
    required this.negative,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final sign = negative ? '-' : '+';
    final effectiveColor = negative ? Colors.redAccent : accentColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            negative
                ? Icons.remove_circle_outline
                : Icons.add_circle_outline,
            color: effectiveColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor.withAlpha(145),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${_money(value)} $currency',
            style: TextStyle(
              color: effectiveColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutstandingBanner extends StatelessWidget {
  final double amount;
  final String currency;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;

  const _OutstandingBanner({
    required this.amount,
    required this.currency,
    required this.borderColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.pending_actions_outlined,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'outstanding_amount'.tr,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${_money(amount)} $currency',
            style: TextStyle(
              color: accentColor,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;
  final bool highlighted;

  const _QuickAmountButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.accentColor,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? accentColor.withAlpha(22) : backgroundColor,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: highlighted ? accentColor : borderColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: highlighted ? accentColor : textColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentPreview extends StatelessWidget {
  final double paymentAmount;
  final double remainingAmount;
  final String currency;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;

  const _PaymentPreview({
    required this.paymentAmount,
    required this.remainingAmount,
    required this.currency,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _PreviewRow(
            label: 'registered_payment'.tr,
            value: '${_money(paymentAmount)} $currency',
            valueColor: accentColor,
            textColor: textColor,
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 10),
          _PreviewRow(
            label: 'remaining_after_payment'.tr,
            value: '${_money(remainingAmount)} $currency',
            valueColor: remainingAmount <= 0 ? accentColor : textColor,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color textColor;

  const _PreviewRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: textColor.withAlpha(160),
              fontSize: 12.5,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

String _money(double value) => value.toStringAsFixed(2);
