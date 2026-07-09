import 'package:crm/contact_panel/tabs/employee_settlements/provider/employee_settlement_dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

Future<Map<String, dynamic>?> showCompensationRuleDialog({
  required BuildContext context,
  required int agreementId,
  CompensationRuleModel? rule,
}) {
  final isMobile = MediaQuery.of(context).size.width < 720;

  if (isMobile) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompensationRuleDialog(
        agreementId: agreementId,
        rule: rule,
        isMobile: true,
      ),
    );
  }

  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CompensationRuleDialog(
      agreementId: agreementId,
      rule: rule,
    ),
  );
}

class _CompensationRuleDialog extends ConsumerStatefulWidget {
  final int agreementId;
  final CompensationRuleModel? rule;
  final bool isMobile;

  const _CompensationRuleDialog({
    required this.agreementId,
    required this.rule,
    this.isMobile = false,
  });

  @override
  ConsumerState<_CompensationRuleDialog> createState() =>
      _CompensationRuleDialogState();
}

class _CompensationRuleDialogState
    extends ConsumerState<_CompensationRuleDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _code;
  late final TextEditingController _eventType;
  late final TextEditingController _fixedAmount;
  late final TextEditingController _percentageRate;
  late final TextEditingController _unitRate;
  late final TextEditingController _minimumAmount;
  late final TextEditingController _maximumAmount;
  late final TextEditingController _order;

  late String _direction;
  late String _method;
  late String _eventPreset;
  late bool _active;
  late bool _employeeVisible;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final rule = widget.rule;

    _title = TextEditingController(text: rule?.title ?? '');
    _code = TextEditingController(text: rule?.code ?? '');
    _eventType = TextEditingController(text: rule?.eventType ?? '');
    _fixedAmount = TextEditingController(
      text: rule?.fixedAmount.toStringAsFixed(2) ?? '0.00',
    );
    _percentageRate = TextEditingController(
      text: rule?.percentageRate.toStringAsFixed(4) ?? '0.0000',
    );
    _unitRate = TextEditingController(
      text: rule?.unitRate.toStringAsFixed(4) ?? '0.0000',
    );
    _minimumAmount = TextEditingController(
      text: rule?.minimumAmount?.toStringAsFixed(2) ?? '',
    );
    _maximumAmount = TextEditingController(
      text: rule?.maximumAmount?.toStringAsFixed(2) ?? '',
    );
    _order = TextEditingController(
      text: (rule?.calculationOrder ?? 100).toString(),
    );

    _direction = rule?.direction ?? 'earning';
    _method = rule?.calculationMethod ?? 'percentage';

    final currentEventType = rule?.eventType.trim() ?? '';
    _eventPreset = _eventPresets.contains(currentEventType)
        ? currentEventType
        : currentEventType.isNotEmpty
            ? 'custom'
            : 'transaction.closed';

    _active = rule?.isActive ?? true;
    _employeeVisible = rule?.isEmployeeVisible ?? true;

    _title.addListener(_onEditableFieldChanged);
    _fixedAmount.addListener(_onEditableFieldChanged);
    _percentageRate.addListener(_onEditableFieldChanged);
    _unitRate.addListener(_onEditableFieldChanged);
    _minimumAmount.addListener(_onEditableFieldChanged);
    _maximumAmount.addListener(_onEditableFieldChanged);
  }

  @override
  void dispose() {
    _title.removeListener(_onEditableFieldChanged);
    _fixedAmount.removeListener(_onEditableFieldChanged);
    _percentageRate.removeListener(_onEditableFieldChanged);
    _unitRate.removeListener(_onEditableFieldChanged);
    _minimumAmount.removeListener(_onEditableFieldChanged);
    _maximumAmount.removeListener(_onEditableFieldChanged);

    for (final controller in [
      _title,
      _code,
      _eventType,
      _fixedAmount,
      _percentageRate,
      _unitRate,
      _minimumAmount,
      _maximumAmount,
      _order,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  void _onEditableFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'field_required'.tr
        : null;
  }

  String? _requiredPositiveNumber(String? value) {
    final parsed = _nullableNumber(value ?? '');

    if (parsed == null || parsed <= 0) {
      return 'number_must_be_greater_than_zero'.tr;
    }

    return null;
  }

  String? _optionalNonNegativeNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parsed = _nullableNumber(value);

    if (parsed == null) {
      return 'invalid_number'.tr;
    }

    if (parsed < 0) {
      return 'number_cannot_be_negative'.tr;
    }

    return null;
  }

  String? _orderValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');

    if (parsed == null || parsed < 0) {
      return 'invalid_calculation_order'.tr;
    }

    return null;
  }

  String? _validateRange() {
    final minimum = _nullableNumber(_minimumAmount.text);
    final maximum = _nullableNumber(_maximumAmount.text);

    if (minimum != null && maximum != null && minimum > maximum) {
      return 'minimum_cannot_exceed_maximum'.tr;
    }

    return null;
  }

  String _resolvedEventType() {
    return _eventPreset == 'custom'
        ? _eventType.text.trim()
        : _eventPreset;
  }

  String _resolvedCode() {
    final explicitCode = _code.text.trim();
    return explicitCode.isNotEmpty ? explicitCode : _slugify(_title.text);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final rangeError = _validateRange();
    if (rangeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rangeError)),
      );
      return;
    }

    final eventType = _resolvedEventType();

    if (eventType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('field_required'.tr)),
      );
      return;
    }

    final generatedCode = _resolvedCode();

    if (generatedCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('rule_code_cannot_be_generated'.tr)),
      );
      return;
    }

    setState(() => _isSaving = true);

    Navigator.of(context).pop({
      'agreement': widget.agreementId,
      'title': _title.text.trim(),
      'code': generatedCode,
      'direction': _direction,
      'calculation_method': _method,
      'event_type': eventType,
      'fixed_amount': _number(_fixedAmount.text),
      'percentage_rate': _number(_percentageRate.text),
      'unit_rate': _number(_unitRate.text),
      'minimum_amount': _nullableNumber(_minimumAmount.text),
      'maximum_amount': _nullableNumber(_maximumAmount.text),
      'calculation_order': int.tryParse(_order.text.trim()) ?? 100,
      'is_active': _active,
      'is_employee_visible': _employeeVisible,
      'conditions': <String, dynamic>{},
      'tiers': <dynamic>[],
      'formula': <String, dynamic>{},
      'metadata': <String, dynamic>{},
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 720;

    if (widget.isMobile) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (sheetContext, scrollController) {
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border.all(color: theme.dashboardBoarder),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                _DialogHeader(
                  isEditing: widget.rule != null,
                  textColor: theme.textColor,
                  accentColor: theme.themeColor,
                  borderColor: theme.dashboardBoarder,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _buildForm(
                    isCompact: isCompact,
                    scrollController: scrollController,
                  ),
                ),
                _DialogFooter(
                  backgroundColor: theme.dashboardContainer,
                  borderColor: theme.dashboardBoarder,
                  isSaving: _isSaving,
                  isEditing: widget.rule != null,
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: _submit,
                ),
              ],
            ),
          );
        },
      );
    }

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
          maxWidth: 860,
          maxHeight: screenSize.height * 0.92,
        ),
        child: Column(
          children: [
            _DialogHeader(
              isEditing: widget.rule != null,
              textColor: theme.textColor,
              accentColor: theme.themeColor,
              borderColor: theme.dashboardBoarder,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: _buildForm(isCompact: isCompact),
            ),
            _DialogFooter(
              backgroundColor: theme.dashboardContainer,
              borderColor: theme.dashboardBoarder,
              isSaving: _isSaving,
              isEditing: widget.rule != null,
              onCancel: () => Navigator.of(context).pop(),
              onSave: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm({
    required bool isCompact,
    ScrollController? scrollController,
  }) {
    final theme = ref.watch(themeColorsProvider);

    return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(isCompact ? 16 : 22),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fieldWidth = constraints.maxWidth >= 680
                          ? (constraints.maxWidth - 14) / 2
                          : constraints.maxWidth;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _RulePreviewCard(
                            title: _title.text,
                            direction: _direction,
                            method: _method,
                            eventType: _resolvedEventType(),
                            amountText: _buildPreviewAmount(),
                            isActive: _active,
                            isEmployeeVisible: _employeeVisible,
                            backgroundColor: theme.adPopBackground,
                            borderColor: theme.dashboardBoarder,
                            textColor: theme.textColor,
                            accentColor: theme.themeColor,
                          ),
                          const SizedBox(height: 16),
                          _SectionPanel(
                            title: 'rule_basic_information'.tr,
                            subtitle: 'rule_basic_information_hint'.tr,
                            icon: Icons.badge_outlined,
                            backgroundColor: theme.adPopBackground,
                            borderColor: theme.dashboardBoarder,
                            textColor: theme.textColor,
                            child: Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                SizedBox(
                                  width: fieldWidth,
                                  child: CoreTextFormField(
                                    label: 'rule_name'.tr,
                                    controller: _title,
                                    autofocus: true,
                                    textInputAction: TextInputAction.next,
                                    prefixIcon: Icon(
                                      Icons.edit_outlined,
                                      color: theme.textColor.withAlpha(170),
                                    ),
                                    validator: _required,
                                  ),
                                ),
                                SizedBox(
                                  width: fieldWidth,
                                  child: CoreTextFormField(
                                    label: 'rule_code'.tr,
                                    controller: _code,
                                    textInputAction: TextInputAction.next,
                                    hintText: _slugify(_title.text).isEmpty
                                        ? 'sales_commission'
                                        : _slugify(_title.text),
                                    helperText:
                                        'rule_code_auto_generated_hint'.tr,
                                    prefixIcon: Icon(
                                      Icons.code_outlined,
                                      color: theme.textColor.withAlpha(170),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z0-9_\-]'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionPanel(
                            title: 'rule_calculation_configuration'.tr,
                            subtitle: 'rule_calculation_configuration_hint'.tr,
                            icon: Icons.calculate_outlined,
                            backgroundColor: theme.adPopBackground,
                            borderColor: theme.dashboardBoarder,
                            textColor: theme.textColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'rule_direction'.tr,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                LayoutBuilder(
                                  builder: (context, innerConstraints) {
                                    final options = [
                                      _DirectionOption(
                                        value: 'earning',
                                        icon: Icons.trending_up_rounded,
                                        title: 'rule_direction_earning'.tr,
                                        subtitle:
                                            'rule_direction_earning_hint'.tr,
                                      ),
                                      _DirectionOption(
                                        value: 'deduction',
                                        icon: Icons.trending_down_rounded,
                                        title: 'rule_direction_deduction'.tr,
                                        subtitle:
                                            'rule_direction_deduction_hint'.tr,
                                      ),
                                      _DirectionOption(
                                        value: 'reimbursement',
                                        icon: Icons
                                            .replay_circle_filled_outlined,
                                        title:
                                            'rule_direction_reimbursement'.tr,
                                        subtitle:
                                            'rule_direction_reimbursement_hint'
                                                .tr,
                                      ),
                                    ];

                                    if (innerConstraints.maxWidth < 590) {
                                      return Column(
                                        children: [
                                          for (var index = 0;
                                              index < options.length;
                                              index++) ...[
                                            _DirectionCard(
                                              selected: _direction ==
                                                  options[index].value,
                                              option: options[index],
                                              backgroundColor:
                                                  theme.dashboardContainer,
                                              borderColor:
                                                  theme.dashboardBoarder,
                                              textColor: theme.textColor,
                                              accentColor: theme.themeColor,
                                              onTap: () {
                                                setState(() {
                                                  _direction =
                                                      options[index].value;
                                                });
                                              },
                                            ),
                                            if (index < options.length - 1)
                                              const SizedBox(height: 8),
                                          ],
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        for (var index = 0;
                                            index < options.length;
                                            index++) ...[
                                          Expanded(
                                            child: _DirectionCard(
                                              selected: _direction ==
                                                  options[index].value,
                                              option: options[index],
                                              backgroundColor:
                                                  theme.dashboardContainer,
                                              borderColor:
                                                  theme.dashboardBoarder,
                                              textColor: theme.textColor,
                                              accentColor: theme.themeColor,
                                              onTap: () {
                                                setState(() {
                                                  _direction =
                                                      options[index].value;
                                                });
                                              },
                                            ),
                                          ),
                                          if (index < options.length - 1)
                                            const SizedBox(width: 8),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  children: [
                                    _dropdown(
                                      width: fieldWidth,
                                      label: 'calculation_method'.tr,
                                      value: _method,
                                      options: const [
                                        'fixed',
                                        'percentage',
                                        'per_unit',
                                        'tiered',
                                        'manual',
                                        'custom',
                                      ],
                                      display: (value) =>
                                          'rule_method_$value'.tr,
                                      onChanged: (value) {
                                        setState(() => _method = value);
                                      },
                                    ),
                                    _dropdown(
                                      width: fieldWidth,
                                      label: 'event_type'.tr,
                                      value: _eventPreset,
                                      options: _eventPresets,
                                      display: (value) => value == 'custom'
                                          ? 'custom_event'.tr
                                          : 'event_${value.replaceAll('.', '_')}'
                                              .tr,
                                      onChanged: (value) {
                                        setState(() {
                                          _eventPreset = value;
                                        });
                                      },
                                    ),
                                    if (_eventPreset == 'custom')
                                      SizedBox(
                                        width: constraints.maxWidth,
                                        child: CoreTextFormField(
                                          label: 'custom_event_type'.tr,
                                          controller: _eventType,
                                          hintText: 'custom.completed',
                                          helperText:
                                              'custom_event_type_hint'.tr,
                                          prefixIcon: Icon(
                                            Icons.bolt_outlined,
                                            color:
                                                theme.textColor.withAlpha(170),
                                          ),
                                          validator: _required,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _MethodHelpCard(
                                  method: _method,
                                  textColor: theme.textColor,
                                  accentColor: theme.themeColor,
                                  backgroundColor:
                                      theme.dashboardContainer,
                                  borderColor: theme.dashboardBoarder,
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  children: [
                                    if (_method == 'fixed')
                                      _numberField(
                                        width: fieldWidth,
                                        label: 'fixed_amount'.tr,
                                        controller: _fixedAmount,
                                        suffix: 'PLN',
                                        validator: _requiredPositiveNumber,
                                        icon: Icons.payments_outlined,
                                        textColor: theme.textColor,
                                      ),
                                    if (_method == 'percentage' ||
                                        _method == 'tiered')
                                      _numberField(
                                        width: fieldWidth,
                                        label: 'percentage_rate'.tr,
                                        controller: _percentageRate,
                                        suffix: '%',
                                        validator: _requiredPositiveNumber,
                                        icon: Icons.percent_outlined,
                                        textColor: theme.textColor,
                                        decimals: 4,
                                      ),
                                    if (_method == 'per_unit')
                                      _numberField(
                                        width: fieldWidth,
                                        label: 'unit_rate'.tr,
                                        controller: _unitRate,
                                        suffix: 'PLN',
                                        validator: _requiredPositiveNumber,
                                        icon: Icons.straighten_outlined,
                                        textColor: theme.textColor,
                                        decimals: 4,
                                      ),
                                    _numberField(
                                      width: fieldWidth,
                                      label: 'minimum_amount_optional'.tr,
                                      controller: _minimumAmount,
                                      suffix: 'PLN',
                                      validator: _optionalNonNegativeNumber,
                                      icon: Icons.vertical_align_bottom_outlined,
                                      textColor: theme.textColor,
                                      required: false,
                                    ),
                                    _numberField(
                                      width: fieldWidth,
                                      label: 'maximum_amount_optional'.tr,
                                      controller: _maximumAmount,
                                      suffix: 'PLN',
                                      validator: _optionalNonNegativeNumber,
                                      icon: Icons.vertical_align_top_outlined,
                                      textColor: theme.textColor,
                                      required: false,
                                    ),
                                    SizedBox(
                                      width: fieldWidth,
                                      child: CoreTextFormField(
                                        label: 'calculation_order'.tr,
                                        controller: _order,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.done,
                                        helperText:
                                            'calculation_order_hint'.tr,
                                        prefixIcon: Icon(
                                          Icons.low_priority_outlined,
                                          color:
                                              theme.textColor.withAlpha(170),
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        validator: _orderValidator,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionPanel(
                            title: 'rule_availability'.tr,
                            subtitle: 'rule_availability_hint'.tr,
                            icon: Icons.tune_outlined,
                            backgroundColor: theme.adPopBackground,
                            borderColor: theme.dashboardBoarder,
                            textColor: theme.textColor,
                            child: Column(
                              children: [
                                _SettingsTile(
                                  value: _active,
                                  icon: _active
                                      ? Icons.toggle_on_outlined
                                      : Icons.toggle_off_outlined,
                                  title: 'rule_active'.tr,
                                  subtitle: _active
                                      ? 'rule_active_enabled_hint'.tr
                                      : 'rule_active_disabled_hint'.tr,
                                  backgroundColor:
                                      theme.dashboardContainer,
                                  borderColor: theme.dashboardBoarder,
                                  textColor: theme.textColor,
                                  accentColor: theme.themeColor,
                                  onChanged: (value) {
                                    setState(() => _active = value);
                                  },
                                ),
                                const SizedBox(height: 10),
                                _SettingsTile(
                                  value: _employeeVisible,
                                  icon: _employeeVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  title: 'rule_employee_visible'.tr,
                                  subtitle: _employeeVisible
                                      ? 'rule_employee_visible_enabled_hint'.tr
                                      : 'rule_employee_visible_disabled_hint'
                                          .tr,
                                  backgroundColor:
                                      theme.dashboardContainer,
                                  borderColor: theme.dashboardBoarder,
                                  textColor: theme.textColor,
                                  accentColor: theme.themeColor,
                                  onChanged: (value) {
                                    setState(
                                      () => _employeeVisible = value,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
  }

  String _buildPreviewAmount() {
    switch (_method) {
      case 'fixed':
        return '${_formattedNumber(_number(_fixedAmount.text), 2)} PLN';
      case 'percentage':
        return '${_formattedNumber(_number(_percentageRate.text), 4)}%';
      case 'per_unit':
        return '${_formattedNumber(_number(_unitRate.text), 4)} PLN / ${'unit'.tr}';
      case 'tiered':
        return '${_formattedNumber(_number(_percentageRate.text), 4)}%+';
      case 'manual':
        return 'rule_preview_manual'.tr;
      default:
        return 'rule_preview_custom'.tr;
    }
  }

  Widget _dropdown({
    required double width,
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    String Function(String)? display,
  }) {
    return SizedBox(
      width: width,
      child: CoreDropdown<String>(
        label: label,
        value: value,
        options: options,
        display: display,
        onChanged: (next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }

  Widget _numberField({
    required double width,
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    required Color textColor,
    String? suffix,
    bool required = true,
    int decimals = 2,
  }) {
    return SizedBox(
      width: width,
      child: CoreTextFormField(
        label: label,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        prefixIcon: Icon(
          icon,
          color: textColor.withAlpha(170),
        ),
        suffixIcon: suffix == null
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: textColor.withAlpha(180),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp('^\\d*[.,]?\\d{0,$decimals}'),
          ),
        ],
        validator: validator,
        helperText: required ? null : 'optional_field'.tr,
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final bool isEditing;
  final Color textColor;
  final Color accentColor;
  final Color borderColor;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.isEditing,
    required this.textColor,
    required this.accentColor,
    required this.borderColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withAlpha(60)),
            ),
            child: Icon(
              Icons.rule_folder_outlined,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? 'edit_compensation_rule'.tr
                      : 'add_compensation_rule'.tr,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isEditing
                      ? 'edit_compensation_rule_hint'.tr
                      : 'add_compensation_rule_hint'.tr,
                  style: TextStyle(
                    color: textColor.withAlpha(155),
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
  final bool isSaving;
  final bool isEditing;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _DialogFooter({
    required this.backgroundColor,
    required this.borderColor,
    required this.isSaving,
    required this.isEditing,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CoreOutlinedButton(
            onPressed: isSaving ? null : onCancel,
            child: Text('cancel'.tr),
          ),
          const SizedBox(width: 10),
          CoreFilledButton(
            onPressed: isSaving ? null : onSave,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSaving)
                  const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    isEditing ? Icons.save_outlined : Icons.add_rounded,
                    size: 18,
                  ),
                const SizedBox(width: 7),
                Text(
                  isEditing ? 'save_changes'.tr : 'add_rule'.tr,
                ),
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
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _SectionPanel({
    required this.title,
    required this.subtitle,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: textColor.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: textColor.withAlpha(190),
                ),
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
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withAlpha(145),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RulePreviewCard extends StatelessWidget {
  final String title;
  final String direction;
  final String method;
  final String eventType;
  final String amountText;
  final bool isActive;
  final bool isEmployeeVisible;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;

  const _RulePreviewCard({
    required this.title,
    required this.direction,
    required this.method,
    required this.eventType,
    required this.amountText,
    required this.isActive,
    required this.isEmployeeVisible,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final directionIcon = switch (direction) {
      'deduction' => Icons.trending_down_rounded,
      'reimbursement' => Icons.replay_circle_filled_outlined,
      _ => Icons.trending_up_rounded,
    };

    final directionColor = direction == 'deduction'
        ? Colors.redAccent
        : accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: directionColor.withAlpha(24),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              directionIcon,
              color: directionColor,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.trim().isEmpty ? 'new_compensation_rule'.tr : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _PreviewBadge(
                      label: 'rule_method_$method'.tr,
                      color: accentColor,
                    ),
                    _PreviewBadge(
                      label: eventType.isEmpty
                          ? 'event_not_selected'.tr
                          : eventType,
                      color: textColor.withAlpha(150),
                    ),
                    _PreviewBadge(
                      label: isActive
                          ? 'agreement_status_active'.tr
                          : 'agreement_status_paused'.tr,
                      color: isActive
                          ? accentColor
                          : textColor.withAlpha(135),
                    ),
                    if (!isEmployeeVisible)
                      _PreviewBadge(
                        label: 'hidden_from_employee'.tr,
                        color: textColor.withAlpha(135),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountText,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: directionColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PreviewBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
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

class _DirectionCard extends StatelessWidget {
  final bool selected;
  final _DirectionOption option;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _DirectionCard({
    required this.selected,
    required this.option,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accentColor.withAlpha(20) : backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 104),
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
                    option.icon,
                    size: 20,
                    color:
                        selected ? accentColor : textColor.withAlpha(165),
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                    color: selected
                        ? accentColor
                        : textColor.withAlpha(80),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                option.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option.subtitle,
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

class _MethodHelpCard extends StatelessWidget {
  final String method;
  final Color textColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;

  const _MethodHelpCard({
    required this.method,
    required this.textColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final helpKey = switch (method) {
      'fixed' => 'rule_help_fixed',
      'percentage' => 'rule_help_percentage',
      'per_unit' => 'rule_help_per_unit',
      'tiered' => 'rule_help_tiered',
      'manual' => 'rule_help_manual',
      _ => 'rule_help_custom',
    };

    final icon = switch (method) {
      'fixed' => Icons.payments_outlined,
      'percentage' => Icons.percent_outlined,
      'per_unit' => Icons.straighten_outlined,
      'tiered' => Icons.stairs_outlined,
      'manual' => Icons.edit_note_outlined,
      _ => Icons.functions_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              helpKey.tr,
              style: TextStyle(
                color: textColor.withAlpha(180),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final bool value;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitle,
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: value
                      ? accentColor.withAlpha(22)
                      : textColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: value
                      ? accentColor
                      : textColor.withAlpha(145),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withAlpha(145),
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

double _number(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0.0;
}

double? _nullableNumber(String value) {
  final normalized = value.trim().replaceAll(',', '.');

  if (normalized.isEmpty) {
    return null;
  }

  return double.tryParse(normalized);
}

String _formattedNumber(double value, int decimals) {
  return value.toStringAsFixed(decimals);
}

String _slugify(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

const _eventPresets = [
  'transaction.closed',
  'hours.approved',
  'order.completed',
  'project.completed',
  'project.milestone',
  'task.completed',
  'lead.converted',
  'campaign.result',
  'unit.completed',
  'custom',
];
