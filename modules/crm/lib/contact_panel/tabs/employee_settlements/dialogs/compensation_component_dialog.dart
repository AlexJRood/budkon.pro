import "package:crm/contact_panel/tabs/employee_settlements/provider/employee_settlement_dashboard_provider.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:get/get_utils/get_utils.dart";
import "package:core/theme/apptheme.dart";
import "package:core/theme/text_field.dart";

Future<CompensationComponentModel?> showCompensationComponentDialog({
  required BuildContext context,
  required String type,
  required String currency,
  CompensationComponentModel? component,
}) {
  return showDialog<CompensationComponentModel>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CompensationComponentDialog(
      type: type,
      currency: currency,
      component: component,
    ),
  );
}

class _CompensationComponentDialog extends ConsumerStatefulWidget {
  final String type;
  final String currency;
  final CompensationComponentModel? component;

  const _CompensationComponentDialog({
    required this.type,
    required this.currency,
    required this.component,
  });

  @override
  ConsumerState<_CompensationComponentDialog> createState() =>
      _CompensationComponentDialogState();
}

class _CompensationComponentDialogState
    extends ConsumerState<_CompensationComponentDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _hourlyRate;
  late final TextEditingController _expectedHours;
  late final TextEditingController _percentageRate;
  late final TextEditingController _unitRate;
  late final TextEditingController _minimumAmount;
  late final TextEditingController _maximumAmount;
  late final TextEditingController _eventType;
  late final TextEditingController _exclusiveGroup;
  late final TextEditingController _milestoneCode;

  late String _calculationMethod;
  late String _commissionBasis;
  late String _stackingPolicy;
  late String _direction;
  late bool _requiresTimeEntries;
  late bool _isActive;
  late bool _isEmployeeVisible;

  String get _type => widget.type;
  bool get _isFixed => _type == "fixed";
  bool get _isHourly => _type == "hourly";
  bool get _isCommission => _type == "commission";
  bool get _isMilestone => _type == "milestone";
  bool get _showsRuleOptions => !_isFixed && !_isHourly;

  @override
  void initState() {
    super.initState();
    final value = widget.component;

    _title = TextEditingController(
      text: value?.title ?? _defaultTitle(_type),
    );
    _amount = TextEditingController(
      text: _initialAmount(value).toStringAsFixed(2),
    );
    _hourlyRate = TextEditingController(
      text: value?.hourlyRate.toStringAsFixed(4) ?? "0.0000",
    );
    _expectedHours = TextEditingController(
      text: value?.expectedHoursPerPeriod.toStringAsFixed(2) ?? "0.00",
    );
    _percentageRate = TextEditingController(
      text: value?.percentageRate.toStringAsFixed(4) ?? "0.0000",
    );
    _unitRate = TextEditingController(
      text: value?.unitRate.toStringAsFixed(4) ?? "0.0000",
    );
    _minimumAmount = TextEditingController(
      text: value?.minimumAmount?.toStringAsFixed(2) ?? "",
    );
    _maximumAmount = TextEditingController(
      text: value?.maximumAmount?.toStringAsFixed(2) ?? "",
    );
    _eventType = TextEditingController(
      text: value?.eventType.isNotEmpty == true
          ? value!.eventType
          : _defaultEvent(_type),
    );
    _exclusiveGroup = TextEditingController(
      text: value?.exclusiveGroup ?? "",
    );
    _milestoneCode = TextEditingController(
      text: _extractMilestoneCode(value),
    );

    _calculationMethod = value?.calculationMethod ?? _defaultMethod(_type);
    _commissionBasis = value?.commissionBasis ?? "revenue";
    _stackingPolicy = value?.stackingPolicy ?? "stack";
    _direction = value?.direction ?? _defaultDirection(_type);
    _requiresTimeEntries = value?.requiresTimeEntries ?? false;
    _isActive = value?.isActive ?? true;
    _isEmployeeVisible = value?.isEmployeeVisible ?? true;
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _amount,
      _hourlyRate,
      _expectedHours,
      _percentageRate,
      _unitRate,
      _minimumAmount,
      _maximumAmount,
      _eventType,
      _exclusiveGroup,
      _milestoneCode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) {
    return (value ?? "").trim().isEmpty ? "field_required".tr : null;
  }

  String? _positive(String? value) {
    final parsed = _parseNumber(value);
    if (parsed == null || parsed <= 0) {
      return "number_must_be_greater_than_zero".tr;
    }
    return null;
  }

  String? _optionalNumber(String? value) {
    if ((value ?? "").trim().isEmpty) {
      return null;
    }
    return _parseNumber(value) == null ? "invalid_number".tr : null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final minimum = _parseNumber(_minimumAmount.text);
    final maximum = _parseNumber(_maximumAmount.text);
    if (minimum != null && maximum != null && minimum > maximum) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("minimum_cannot_exceed_maximum".tr)),
      );
      return;
    }

    final conditions = Map<String, dynamic>.from(
      widget.component?.conditions ?? const <String, dynamic>{},
    );

    if (_isMilestone) {
      final milestoneCode = _milestoneCode.text.trim();
      if (milestoneCode.isEmpty) {
        conditions.remove("metadata_equals");
      } else {
        conditions["metadata_equals"] = <String, dynamic>{
          "milestone_code": milestoneCode,
        };
      }
    }

    Navigator.of(context).pop(
      CompensationComponentModel(
        id: widget.component?.id,
        type: _type,
        title: _title.text.trim(),
        code: widget.component?.code ?? "",
        amount: _isFixed ? _parseNumber(_amount.text) ?? 0 : 0,
        hourlyRate: _isHourly ? _parseNumber(_hourlyRate.text) ?? 0 : 0,
        expectedHoursPerPeriod:
            _isHourly ? _parseNumber(_expectedHours.text) ?? 0 : 0,
        requiresTimeEntries: _isHourly && _requiresTimeEntries,
        direction: _direction,
        calculationMethod:
            _showsRuleOptions ? _calculationMethod : "fixed",
        eventType: _showsRuleOptions ? _eventType.text.trim() : "",
        fixedAmount: _showsRuleOptions && _calculationMethod == "fixed"
            ? _parseNumber(_amount.text) ?? 0
            : 0,
        percentageRate:
            _calculationMethod == "percentage" || _isCommission
                ? _parseNumber(_percentageRate.text) ?? 0
                : 0,
        unitRate: _calculationMethod == "per_unit"
            ? _parseNumber(_unitRate.text) ?? 0
            : 0,
        commissionBasis: _commissionBasis,
        minimumAmount: minimum,
        maximumAmount: maximum,
        calculationOrder: widget.component?.calculationOrder ?? 100,
        stackingPolicy: _stackingPolicy,
        exclusiveGroup: _exclusiveGroup.text.trim(),
        isActive: _isActive,
        isEmployeeVisible: _isEmployeeVisible,
        conditions: conditions,
        tiers: widget.component?.tiers ?? const <dynamic>[],
        formula: widget.component?.formula ?? const <String, dynamic>{},
        metadata: widget.component?.metadata ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final screen = MediaQuery.of(context).size;
    final isCompact = screen.width < 680;

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
          maxWidth: 760,
          maxHeight: screen.height * 0.92,
        ),
        child: Column(
          children: [
            _ComponentDialogHeader(
              type: _type,
              isEditing: widget.component != null,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isCompact ? 16 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ComponentPreview(
                        componentType: _type,
                        title: _title.text,
                        currency: widget.currency,
                        amount: _parseNumber(_amount.text) ?? 0,
                        hourlyRate: _parseNumber(_hourlyRate.text) ?? 0,
                        percentageRate:
                            _parseNumber(_percentageRate.text) ?? 0,
                        unitRate: _parseNumber(_unitRate.text) ?? 0,
                        eventType: _eventType.text,
                        active: _isActive,
                      ),
                      const SizedBox(height: 16),
                      _ComponentSection(
                        title: "component_basic_information".tr,
                        icon: Icons.badge_outlined,
                        child: CoreTextFormField(
                          label: "component_name".tr,
                          controller: _title,
                          validator: _required,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ComponentSection(
                        title: "component_calculation".tr,
                        icon: Icons.calculate_outlined,
                        child: _buildCalculationFields(),
                      ),
                      if (_showsRuleOptions) ...[
                        const SizedBox(height: 14),
                        _ComponentSection(
                          title: "component_matching_and_stacking".tr,
                          icon: Icons.account_tree_outlined,
                          child: _buildRuleFields(),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _ComponentSection(
                        title: "component_visibility_and_status".tr,
                        icon: Icons.visibility_outlined,
                        child: Column(
                          children: [
                            _ComponentSwitchTile(
                              value: _isActive,
                              title: "rule_active".tr,
                              subtitle: _isActive
                                  ? "rule_active_enabled_hint".tr
                                  : "rule_active_disabled_hint".tr,
                              onChanged: (value) {
                                setState(() => _isActive = value);
                              },
                            ),
                            const SizedBox(height: 10),
                            _ComponentSwitchTile(
                              value: _isEmployeeVisible,
                              title: "rule_employee_visible".tr,
                              subtitle: _isEmployeeVisible
                                  ? "rule_employee_visible_enabled_hint".tr
                                  : "rule_employee_visible_disabled_hint".tr,
                              onChanged: (value) {
                                setState(() => _isEmployeeVisible = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _ComponentDialogFooter(
              onCancel: () => Navigator.of(context).pop(),
              onSave: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationFields() {
    if (_isFixed) {
      return _moneyField(
        controller: _amount,
        label: "base_amount".tr,
        validator: _positive,
      );
    }

    if (_isHourly) {
      return Column(
        children: [
          _moneyField(
            controller: _hourlyRate,
            label: "hourly_rate".tr,
            suffix: "${widget.currency}/h",
            validator: _positive,
          ),
          const SizedBox(height: 12),
          _ComponentSwitchTile(
            value: _requiresTimeEntries,
            title: "requires_time_entries".tr,
            subtitle: _requiresTimeEntries
                ? "hourly_time_entries_enabled_hint".tr
                : "hourly_time_entries_disabled_hint".tr,
            onChanged: (value) {
              setState(() => _requiresTimeEntries = value);
            },
          ),
          if (!_requiresTimeEntries) ...[
            const SizedBox(height: 12),
            CoreTextFormField(
              label: "expected_hours_per_period".tr,
              controller: _expectedHours,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_decimalFormatter(2)],
              validator: _positive,
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        CoreDropdown<String>(
          label: "calculation_method".tr,
          value: _calculationMethod,
          options: const [
            "fixed",
            "percentage",
            "per_unit",
            "tiered",
            "custom",
          ],
          display: (value) => "rule_method_$value".tr,
          onChanged: (value) {
            if (value != null) {
              setState(() => _calculationMethod = value);
            }
          },
        ),
        const SizedBox(height: 12),
        if (_calculationMethod == "fixed")
          _moneyField(
            controller: _amount,
            label: "fixed_amount".tr,
            validator: _positive,
          ),
        if (_calculationMethod == "percentage") ...[
          CoreTextFormField(
            label: "percentage_rate".tr,
            controller: _percentageRate,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalFormatter(4)],
            suffixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(widthFactor: 1, child: Text("%")),
            ),
            validator: _positive,
          ),
          const SizedBox(height: 12),
          CoreDropdown<String>(
            label: "commission_basis".tr,
            value: _commissionBasis,
            options: const [
              "revenue",
              "net_revenue",
              "transaction_value",
              "company_commission",
              "margin",
              "profit",
              "custom",
            ],
            display: (value) => "commission_basis_$value".tr,
            onChanged: (value) {
              if (value != null) {
                setState(() => _commissionBasis = value);
              }
            },
          ),
        ],
        if (_calculationMethod == "per_unit")
          _moneyField(
            controller: _unitRate,
            label: "unit_rate".tr,
            validator: _positive,
          ),
        if (_calculationMethod == "tiered")
          _ComponentHint(text: "tiered_rule_editor_hint".tr),
        if (_calculationMethod == "custom")
          _ComponentHint(text: "custom_rule_adapter_hint".tr),
        const SizedBox(height: 12),
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
                  child: CoreTextFormField(
                    label: "minimum_amount_optional".tr,
                    controller: _minimumAmount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [_decimalFormatter(2)],
                    validator: _optionalNumber,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: CoreTextFormField(
                    label: "maximum_amount_optional".tr,
                    controller: _maximumAmount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [_decimalFormatter(2)],
                    validator: _optionalNumber,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRuleFields() {
    return Column(
      children: [
        CoreTextFormField(
          label: "event_type".tr,
          controller: _eventType,
          hintText: _defaultEvent(_type),
          validator: _required,
          onChanged: (_) => setState(() {}),
        ),
        if (_isMilestone) ...[
          const SizedBox(height: 12),
          CoreTextFormField(
            label: "milestone_code".tr,
            controller: _milestoneCode,
            hintText: "mvp_completed",
          ),
        ],
        const SizedBox(height: 12),
        CoreDropdown<String>(
          label: "stacking_policy".tr,
          value: _stackingPolicy,
          options: const [
            "stack",
            "first_match",
            "highest",
            "exclusive",
          ],
          display: (value) => "stacking_policy_$value".tr,
          onChanged: (value) {
            if (value != null) {
              setState(() => _stackingPolicy = value);
            }
          },
        ),
        if (_stackingPolicy != "stack") ...[
          const SizedBox(height: 12),
          CoreTextFormField(
            label: "exclusive_group".tr,
            controller: _exclusiveGroup,
            hintText: "sales_commission",
          ),
        ],
        if (_type == "deduction" || _type == "reimbursement") ...[
          const SizedBox(height: 12),
          CoreDropdown<String>(
            label: "direction".tr,
            value: _direction,
            options: const ["earning", "deduction", "reimbursement"],
            display: (value) => "rule_direction_$value".tr,
            onChanged: (value) {
              if (value != null) {
                setState(() => _direction = value);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _moneyField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    String? suffix,
  }) {
    return CoreTextFormField(
      label: label,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_decimalFormatter(4)],
      suffixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          widthFactor: 1,
          child: Text(suffix ?? widget.currency),
        ),
      ),
      validator: validator,
      onChanged: (_) => setState(() {}),
    );
  }
}

class _ComponentDialogHeader extends ConsumerWidget {
  final String type;
  final bool isEditing;
  final VoidCallback onClose;

  const _ComponentDialogHeader({
    required this.type,
    required this.isEditing,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 10, 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dashboardBoarder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(22),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              _componentIcon(type),
              color: theme.themeColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? "edit_compensation_component".tr
                      : "add_compensation_component".tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "component_type_${type}_hint".tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(150),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          CoreIconButton(
            icon: Icons.close_rounded,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _ComponentDialogFooter extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _ComponentDialogFooter({
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CoreOutlinedButton(
            onPressed: onCancel,
            child: Text("cancel".tr),
          ),
          const SizedBox(width: 10),
          CoreFilledButton(
            onPressed: onSave,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.save_outlined, size: 18),
                const SizedBox(width: 7),
                Text("save".tr),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentSection extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ComponentSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.themeColor),
              const SizedBox(width: 9),
              Text(
                title,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w900,
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

class _ComponentPreview extends ConsumerWidget {
  final String componentType;
  final String title;
  final String currency;
  final double amount;
  final double hourlyRate;
  final double percentageRate;
  final double unitRate;
  final String eventType;
  final bool active;

  const _ComponentPreview({
    required this.componentType,
    required this.title,
    required this.currency,
    required this.amount,
    required this.hourlyRate,
    required this.percentageRate,
    required this.unitRate,
    required this.eventType,
    required this.active,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.themeColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(
            _componentIcon(componentType),
            color: theme.themeColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.trim().isEmpty
                      ? "component_type_$componentType".tr
                      : title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _previewValue(
                    componentType: componentType,
                    amount: amount,
                    hourlyRate: hourlyRate,
                    percentageRate: percentageRate,
                    unitRate: unitRate,
                    eventType: eventType,
                    currency: currency,
                  ),
                  style: TextStyle(
                    color: theme.textColor.withAlpha(150),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(active: active),
        ],
      ),
    );
  }
}

class _StatusBadge extends ConsumerWidget {
  final bool active;

  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withAlpha(25)
            : theme.textColor.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? Colors.green.withAlpha(80)
              : theme.dashboardBoarder,
        ),
      ),
      child: Text(
        active ? "active".tr : "inactive".tr,
        style: TextStyle(
          color: active ? Colors.green : theme.textColor.withAlpha(150),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ComponentSwitchTile extends ConsumerWidget {
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  const _ComponentSwitchTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(145),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: theme.themeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ComponentHint extends ConsumerWidget {
  final String text;

  const _ComponentHint({required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: theme.themeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.textColor.withAlpha(155),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _initialAmount(CompensationComponentModel? value) {
  if (value == null) {
    return 0;
  }
  if (value.isFixed && value.amount != 0) {
    return value.amount;
  }
  return value.fixedAmount;
}

String _extractMilestoneCode(CompensationComponentModel? value) {
  final metadataEquals = value?.conditions["metadata_equals"];
  if (metadataEquals is Map && metadataEquals["milestone_code"] != null) {
    return metadataEquals["milestone_code"].toString();
  }
  return "";
}

double? _parseNumber(String? value) {
  final normalized = value?.trim().replaceAll(",", ".") ?? "";
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}

TextInputFormatter _decimalFormatter(int decimals) {
  return FilteringTextInputFormatter.allow(
    RegExp("^\\d*[.,]?\\d{0,$decimals}"),
  );
}

String _defaultTitle(String type) {
  return "component_type_$type".tr;
}

String _defaultMethod(String type) {
  return {
        "commission": "percentage",
        "per_unit": "per_unit",
        "custom": "custom",
      }[type] ??
      "fixed";
}

String _defaultDirection(String type) {
  if (type == "deduction") {
    return "deduction";
  }
  if (type == "reimbursement") {
    return "reimbursement";
  }
  return "earning";
}

String _defaultEvent(String type) {
  return {
        "commission": "invoice.paid",
        "milestone": "project.milestone",
        "per_unit": "unit.completed",
        "per_project": "project.completed",
        "bonus": "custom.bonus",
        "deduction": "custom.deduction",
        "reimbursement": "custom.reimbursement",
        "custom": "custom.completed",
      }[type] ??
      "";
}

IconData _componentIcon(String type) {
  return {
        "fixed": Icons.payments_outlined,
        "hourly": Icons.schedule_outlined,
        "commission": Icons.percent_outlined,
        "milestone": Icons.flag_outlined,
        "per_unit": Icons.straighten_outlined,
        "per_project": Icons.folder_copy_outlined,
        "bonus": Icons.stars_outlined,
        "deduction": Icons.remove_circle_outline,
        "reimbursement": Icons.currency_exchange_outlined,
        "custom": Icons.tune_outlined,
      }[type] ??
      Icons.tune_outlined;
}

String _previewValue({
  required String componentType,
  required double amount,
  required double hourlyRate,
  required double percentageRate,
  required double unitRate,
  required String eventType,
  required String currency,
}) {
  if (componentType == "fixed") {
    return "${amount.toStringAsFixed(2)} $currency";
  }
  if (componentType == "hourly") {
    return "${hourlyRate.toStringAsFixed(4)} $currency/h";
  }
  if (percentageRate > 0) {
    return "${percentageRate.toStringAsFixed(4)}% • $eventType";
  }
  if (unitRate > 0) {
    return "${unitRate.toStringAsFixed(4)} $currency/u • $eventType";
  }
  return "${amount.toStringAsFixed(2)} $currency • $eventType";
}
