import "package:crm/contact_panel/tabs/employee_settlements/dialogs/compensation_component_dialog.dart";
import "package:crm/contact_panel/tabs/employee_settlements/provider/employee_settlement_dashboard_provider.dart";
import "package:crm/contact_panel/tabs/employee_settlements/widgets/compensation_agreement_documents_section.dart";
import "package:crm/contact_panel/tabs/employee_settlements/widgets/compensation_leave_policy_section.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:get/get_utils/get_utils.dart";
import "package:pie_menu/pie_menu.dart";
import "package:core/theme/apptheme.dart";
import "package:core/theme/text_field.dart";

Future<Map<String, dynamic>?> showCompensationAgreementDialog({
  required BuildContext context,
  required int employeeId,
  CompensationAgreementModel? agreement,
}) {
  final isMobile = MediaQuery.of(context).size.width < 760;

  if (isMobile) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompensationAgreementDialog(
        employeeId: employeeId,
        agreement: agreement,
        isMobile: true,
      ),
    );
  }

  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CompensationAgreementDialog(
      employeeId: employeeId,
      agreement: agreement,
    ),
  );
}

class _CompensationAgreementDialog extends ConsumerStatefulWidget {
  final int employeeId;
  final CompensationAgreementModel? agreement;
  final bool isMobile;

  const _CompensationAgreementDialog({
    required this.employeeId,
    required this.agreement,
    this.isMobile = false,
  });

  @override
  ConsumerState<_CompensationAgreementDialog> createState() =>
      _CompensationAgreementDialogState();
}

class _CompensationAgreementDialogState
    extends ConsumerState<_CompensationAgreementDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _paymentDay;
  late final TextEditingController _validFrom;
  late final TextEditingController _validTo;
  late final TextEditingController _minimumGuarantee;
  late final TextEditingController _notes;

  late String _relationshipType;
  late String _payFrequency;
  late String _currency;
  late String _status;
  late bool _autoGenerate;
  late bool _employeeCanViewRules;
  late bool _employeeCanViewSources;
  late List<CompensationComponentModel> _components;
  late CompensationLeavePolicyDraft _leavePolicy;

  bool get _isEditing => widget.agreement != null;

  @override
  void initState() {
    super.initState();
    final agreement = widget.agreement;
    final now = DateTime.now();

    _title = TextEditingController(
      text: agreement?.title ?? "employee_compensation_default_title".tr,
    );
    _paymentDay = TextEditingController(
      text: (agreement?.paymentDay ?? 10).toString(),
    );
    _validFrom = TextEditingController(
      text: agreement?.validFrom ??
          "${now.year.toString().padLeft(4, "0")}-"
              "${now.month.toString().padLeft(2, "0")}-01",
    );
    _validTo = TextEditingController(text: agreement?.validTo ?? "");
    _minimumGuarantee = TextEditingController(
      text: agreement?.minimumGuarantee.toStringAsFixed(2) ?? "0.00",
    );
    _notes = TextEditingController(text: agreement?.notes ?? "");

    _relationshipType = agreement?.relationshipType ?? "employment";
    _payFrequency = agreement?.payFrequency ?? "monthly";
    _currency = agreement?.currency ?? "PLN";
    _status = agreement?.status ?? "active";
    _autoGenerate = agreement?.autoGenerateSettlements ?? true;
    _employeeCanViewRules = agreement?.employeeCanViewRules ?? true;
    _employeeCanViewSources = agreement?.employeeCanViewSources ?? true;
    _components = List<CompensationComponentModel>.from(
      agreement?.components ?? const <CompensationComponentModel>[],
    );

    final customTerms = agreement?.customTerms ?? const <String, dynamic>{};
    _leavePolicy = CompensationLeavePolicyDraft.fromJson(
      Map<String, dynamic>.from(
        customTerms["leave_policy"] is Map
            ? customTerms["leave_policy"]
            : const <String, dynamic>{},
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _paymentDay,
      _validFrom,
      _validTo,
      _minimumGuarantee,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addComponent(String type) async {
    if (type == "fixed" &&
        _components.any((component) => component.isFixed && component.isActive)) {
      _showMessage("fixed_component_already_exists".tr);
      return;
    }
    if (type == "hourly" &&
        _components.any((component) => component.isHourly && component.isActive)) {
      _showMessage("hourly_component_already_exists".tr);
      return;
    }

    final result = await showCompensationComponentDialog(
      context: context,
      type: type,
      currency: _currency,
    );
    if (result != null && mounted) {
      setState(() => _components.add(result));
    }
  }

  Future<void> _editComponent(int index) async {
    final component = _components[index];
    final result = await showCompensationComponentDialog(
      context: context,
      type: component.type,
      currency: _currency,
      component: component,
    );
    if (result != null && mounted) {
      setState(() => _components[index] = result);
    }
  }

  void _removeComponent(int index) {
    final component = _components[index];
    setState(() {
      if (component.id != null) {
        _components[index] = component.copyWith(isActive: false);
      } else {
        _components.removeAt(index);
      }
    });
  }

  void _restoreComponent(int index) {
    final component = _components[index];

    if (component.isFixed &&
        _components.any(
          (candidate) =>
              candidate.isFixed && candidate.isActive && candidate != component,
        )) {
      _showMessage("fixed_component_already_exists".tr);
      return;
    }
    if (component.isHourly &&
        _components.any(
          (candidate) =>
              candidate.isHourly && candidate.isActive && candidate != component,
        )) {
      _showMessage("hourly_component_already_exists".tr);
      return;
    }

    setState(() {
      _components[index] = component.copyWith(isActive: true);
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_components.where((component) => component.isActive).isEmpty) {
      _showMessage("at_least_one_component_required".tr);
      return;
    }

    final validFrom = DateTime.tryParse(_validFrom.text.trim());
    final validToText = _validTo.text.trim();
    final validTo = validToText.isEmpty ? null : DateTime.tryParse(validToText);

    if (validFrom == null || !_isIsoDate(_validFrom.text.trim())) {
      _showMessage("invalid_date".tr);
      return;
    }
    if (validToText.isNotEmpty &&
        (validTo == null || !_isIsoDate(validToText))) {
      _showMessage("invalid_date".tr);
      return;
    }
    if (validTo != null && validTo.isBefore(validFrom)) {
      _showMessage("valid_to_before_valid_from".tr);
      return;
    }

    Navigator.of(context).pop({
      "employee_id": widget.employeeId,
      "title": _title.text.trim(),
      "relationship_type": _relationshipType,
      "pay_frequency": _payFrequency,
      "status": _status,
      "currency": _currency,
      "payment_day": int.tryParse(_paymentDay.text.trim()) ?? 10,
      "minimum_guarantee": _parseNumber(_minimumGuarantee.text) ?? 0,
      "valid_from": _validFrom.text.trim(),
      "valid_to": validToText.isEmpty ? null : validToText,
      "auto_generate_settlements": _autoGenerate,
      "employee_can_view_rules": _employeeCanViewRules,
      "employee_can_view_sources": _employeeCanViewSources,
      "notes": _notes.text.trim(),
      "components": _components
          .map((component) => component.toJson())
          .toList(growable: false),
      "custom_terms": <String, dynamic>{
        "leave_policy": _leavePolicy.toJson(),
      },
      "metadata": <String, dynamic>{
        "configured_with": "multi_component_builder",
      },
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickDate(
    TextEditingController controller, {
    required bool allowEmpty,
  }) async {
    FocusScope.of(context).unfocus();
    final theme = ref.read(themeColorsProvider);
    final current = DateTime.tryParse(controller.text.trim());
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: theme.themeColor,
                  surface: theme.dashboardContainer,
                  onSurface: theme.textColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      controller.text = _formatDate(selected);
      setState(() {});
      return;
    }

    if (allowEmpty && controller.text.trim().isNotEmpty && mounted) {
      final clear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("clear_date".tr),
          content: Text("clear_optional_date_confirmation".tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("cancel".tr),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("clear".tr),
            ),
          ],
        ),
      );
      if (clear == true) {
        controller.clear();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final screen = MediaQuery.of(context).size;
    final isCompact = screen.width < 760;

    if (widget.isMobile) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (sheetContext, scrollController) {
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
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
                _AgreementHeader(
                  isEditing: _isEditing,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _buildForm(
                    isCompact: true,
                    scrollController: scrollController,
                  ),
                ),
                _AgreementFooter(
                  isEditing: _isEditing,
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: _submit,
                ),
              ],
            ),
          );
        },
      );
    }

    return PieCanvas(

      // add details


      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 20,
          vertical: isCompact ? 8 : 20,
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
            maxWidth: 1100,
            maxHeight: screen.height * 0.94,
          ),
          child: Column(
            children: [
              _AgreementHeader(
                isEditing: _isEditing,
                onClose: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: _buildForm(isCompact: isCompact),
              ),
              _AgreementFooter(
                isEditing: _isEditing,
                onCancel: () => Navigator.of(context).pop(),
                onSave: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm({
    required bool isCompact,
    ScrollController? scrollController,
  }) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.all(isCompact ? 14 : 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showSummary = constraints.maxWidth >= 900;
            final form = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AgreementSection(
                              title: "agreement_basic_details".tr,
                              subtitle: "agreement_basic_details_hint".tr,
                              icon: Icons.badge_outlined,
                              child: _buildBasicFields(),
                            ),
                            const SizedBox(height: 14),
                            _AgreementSection(
                              title: "compensation_components".tr,
                              subtitle: "compensation_components_hint".tr,
                              icon: Icons.account_tree_outlined,
                              child: _buildComponents(),
                            ),
                            const SizedBox(height: 14),
                            _AgreementSection(
                              title: "agreement_schedule".tr,
                              subtitle: "agreement_schedule_hint".tr,
                              icon: Icons.calendar_month_outlined,
                              child: _buildScheduleFields(),
                            ),
                            const SizedBox(height: 14),
                            _AgreementSection(
                              title: "leave_entitlement_policy".tr,
                              subtitle: "leave_entitlement_policy_hint".tr,
                              icon: Icons.beach_access_outlined,
                              child: CompensationLeavePolicySection(
                                value: _leavePolicy,
                                currency: _currency,
                                onChanged: (value) {
                                  setState(() => _leavePolicy = value);
                                },
                              ),
                            ),
                            const SizedBox(height: 14),
                            _AgreementSection(
                              title: "agreement_automation_visibility".tr,
                              subtitle:
                                  "agreement_automation_visibility_hint".tr,
                              icon: Icons.visibility_outlined,
                              child: _buildVisibilityFields(),
                            ),
                            const SizedBox(height: 14),
                            _AgreementSection(
                              title: "note".tr,
                              subtitle: "agreement_notes_hint".tr,
                              icon: Icons.notes_outlined,
                              child: CoreTextFormField(
                                label: "note".tr,
                                controller: _notes,
                                minLines: 3,
                                maxLines: 6,
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _AgreementSection(
                              title: "agreement_documents".tr,
                              subtitle: "agreement_documents_hint".tr,
                              icon: Icons.folder_shared_outlined,
                              child: CompensationAgreementDocumentsSection(
                                agreement: widget.agreement,
                                isMobile: isCompact,
                              ),
                            ),
                          ],
                        );
      
                        if (!showSummary) {
                          return form;
                        }
      
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: form),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 310,
                              child: _AgreementSummary(
                                components: _components,
                                currency: _currency,
                                payFrequency: _payFrequency,
                                paymentDay: _paymentDay.text.trim(),
                                status: _status,
                              ),
                            ),
                          ],
                        );
          },
        ),
      ),
    );
  }

  Widget _buildBasicFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.maxWidth >= 620
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: constraints.maxWidth,
              child: CoreTextFormField(
                label: "agreement_title".tr,
                controller: _title,
                validator: (value) => (value ?? "").trim().isEmpty
                    ? "field_required".tr
                    : null,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: CoreDropdown<String>(
                label: "relationship_type".tr,
                value: _relationshipType,
                options: const [
                  "employment",
                  "mandate",
                  "b2b",
                  "agency",
                  "subcontractor",
                  "project",
                  "internship",
                  "partnership",
                  "other",
                ],
                display: (value) => "relationship_type_$value".tr,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _relationshipType = value);
                  }
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: CoreDropdown<String>(
                label: "agreement_status".tr,
                value: _status,
                options: const ["draft", "active", "paused", "ended"],
                display: (value) => "agreement_status_$value".tr,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComponents() {
    final active = _components
        .asMap()
        .entries
        .where((entry) => entry.value.isActive)
        .toList();
    final inactive = _components
        .asMap()
        .entries
        .where((entry) => !entry.value.isActive)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in _componentTypes)
              _AddComponentButton(
                type: type,
                onPressed: () => _addComponent(type),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (active.isEmpty)
          _EmptyComponents(onAddFixed: () => _addComponent("fixed"))
        else
          Column(
            children: [
              for (var index = 0; index < active.length; index++) ...[
                _ComponentCard(
                  component: active[index].value,
                  currency: _currency,
                  onEdit: () => _editComponent(active[index].key),
                  onRemove: () => _removeComponent(active[index].key),
                ),
                if (index < active.length - 1) const SizedBox(height: 9),
              ],
            ],
          ),
        if (inactive.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            "disabled_components".tr,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final entry in inactive)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InactiveComponent(
                component: entry.value,
                onRestore: () => _restoreComponent(entry.key),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildScheduleFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.maxWidth >= 620
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: fieldWidth,
              child: CoreDropdown<String>(
                label: "currency".tr,
                value: _currency,
                options: const ["PLN", "EUR", "USD", "GBP"],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _currency = value);
                  }
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: CoreDropdown<String>(
                label: "pay_frequency".tr,
                value: _payFrequency,
                options: const [
                  "monthly",
                  "weekly",
                  "biweekly",
                  "quarterly",
                  "milestone",
                  "on_demand",
                ],
                display: (value) => "pay_frequency_$value".tr,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _payFrequency = value);
                  }
                },
              ),
            ),
            if (_payFrequency == "monthly")
              SizedBox(
                width: fieldWidth,
                child: CoreTextFormField(
                  label: "payment_day".tr,
                  controller: _paymentDay,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    final day = int.tryParse((value ?? "").trim());
                    return day == null || day < 1 || day > 31
                        ? "payment_day_must_be_1_31".tr
                        : null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
            SizedBox(
              width: fieldWidth,
              child: CoreTextFormField(
                label: "minimum_guarantee".tr,
                controller: _minimumGuarantee,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r"^\d*[.,]?\d{0,2}"),
                  ),
                ],
                suffixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(widthFactor: 1, child: Text(_currency)),
                ),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: CoreTextFormField(
                label: "valid_from".tr,
                controller: _validFrom,
                readOnly: true,
                onTap: () => _pickDate(_validFrom, allowEmpty: false),
                suffixIcon: const Icon(Icons.calendar_month_outlined),
                validator: (value) => !_isIsoDate((value ?? "").trim())
                    ? "invalid_date".tr
                    : null,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: CoreTextFormField(
                label: "valid_to_optional".tr,
                controller: _validTo,
                readOnly: true,
                onTap: () => _pickDate(_validTo, allowEmpty: true),
                suffixIcon: const Icon(Icons.event_outlined),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVisibilityFields() {
    return Column(
      children: [
        _AgreementSwitchTile(
          value: _autoGenerate,
          title: "auto_generate_settlements".tr,
          subtitle: _autoGenerate
              ? "auto_generate_settlements_hint_enabled".tr
              : "auto_generate_settlements_hint_disabled".tr,
          onChanged: (value) => setState(() => _autoGenerate = value),
        ),
        const SizedBox(height: 9),
        _AgreementSwitchTile(
          value: _employeeCanViewRules,
          title: "employee_can_view_rules".tr,
          subtitle: _employeeCanViewRules
              ? "employee_can_view_rules_hint_enabled".tr
              : "employee_can_view_rules_hint_disabled".tr,
          onChanged: (value) {
            setState(() => _employeeCanViewRules = value);
          },
        ),
        const SizedBox(height: 9),
        _AgreementSwitchTile(
          value: _employeeCanViewSources,
          title: "employee_can_view_sources".tr,
          subtitle: _employeeCanViewSources
              ? "employee_can_view_sources_hint_enabled".tr
              : "employee_can_view_sources_hint_disabled".tr,
          onChanged: (value) {
            setState(() => _employeeCanViewSources = value);
          },
        ),
      ],
    );
  }
}

class _AgreementHeader extends ConsumerWidget {
  final bool isEditing;
  final VoidCallback onClose;

  const _AgreementHeader({
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_tree_outlined,
              color: theme.themeColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? "edit_compensation_components".tr
                      : "configure_compensation_components".tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "multi_component_agreement_hint".tr,
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

class _AgreementFooter extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _AgreementFooter({
    required this.isEditing,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
                Icon(
                  isEditing ? Icons.save_outlined : Icons.add_rounded,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Text(isEditing ? "save_changes".tr : "create_agreement".tr),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementSection extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _AgreementSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.themeColor, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.w900,
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
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class _AddComponentButton extends ConsumerWidget {
  final String type;
  final VoidCallback onPressed;

  const _AddComponentButton({
    required this.type,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Material(
      color: theme.dashboardContainer,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_componentIcon(type), size: 17, color: theme.themeColor),
              const SizedBox(width: 6),
              Text(
                "component_type_$type".tr,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.add_rounded, size: 16, color: theme.themeColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComponentCard extends ConsumerWidget {
  final CompensationComponentModel component;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ComponentCard({
    required this.component,
    required this.currency,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(22),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              _componentIcon(component.type),
              color: theme.themeColor,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.title.isEmpty
                      ? "component_type_${component.type}".tr
                      : component.title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _componentDescription(component, currency),
                  style: TextStyle(
                    color: theme.textColor.withAlpha(150),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CoreIconButton(
            icon: Icons.edit_outlined,
            onPressed: onEdit,
          ),
          CoreIconButton(
            icon: Icons.delete_outline_rounded,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _InactiveComponent extends ConsumerWidget {
  final CompensationComponentModel component;
  final VoidCallback onRestore;

  const _InactiveComponent({
    required this.component,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.pause_circle_outline_rounded,
            color: theme.textColor.withAlpha(130),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              component.title,
              style: TextStyle(
                color: theme.textColor.withAlpha(160),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          CoreOutlinedButton(
            onPressed: onRestore,
            child: Text("restore".tr),
          ),
        ],
      ),
    );
  }
}

class _EmptyComponents extends ConsumerWidget {
  final VoidCallback onAddFixed;

  const _EmptyComponents({required this.onAddFixed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_tree_outlined,
            color: theme.themeColor,
            size: 34,
          ),
          const SizedBox(height: 9),
          Text(
            "no_compensation_components".tr,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "no_compensation_components_hint".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textColor.withAlpha(145),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          CoreFilledButton(
            onPressed: onAddFixed,
            child: Text("add_fixed_component".tr),
          ),
        ],
      ),
    );
  }
}

class _AgreementSwitchTile extends ConsumerWidget {
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  const _AgreementSwitchTile({
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

class _AgreementSummary extends ConsumerWidget {
  final List<CompensationComponentModel> components;
  final String currency;
  final String payFrequency;
  final String paymentDay;
  final String status;

  const _AgreementSummary({
    required this.components,
    required this.currency,
    required this.payFrequency,
    required this.paymentDay,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final active = components.where((component) => component.isActive).toList();

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
          Text(
            "agreement_summary".tr,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: "active_components".tr,
            value: active.length.toString(),
          ),
          _SummaryRow(
            label: "frequency".tr,
            value: "pay_frequency_$payFrequency".tr,
          ),
          if (payFrequency == "monthly")
            _SummaryRow(label: "payment_day".tr, value: paymentDay),
          _SummaryRow(
            label: "status".tr,
            value: "agreement_status_$status".tr,
          ),
          const SizedBox(height: 7),
          Divider(color: theme.dashboardBoarder),
          const SizedBox(height: 8),
          if (active.isEmpty)
            Text(
              "no_compensation_components".tr,
              style: TextStyle(
                color: theme.textColor.withAlpha(145),
                fontSize: 12,
              ),
            ),
          for (final component in active)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Icon(
                    _componentIcon(component.type),
                    size: 17,
                    color: theme.themeColor,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      component.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _componentShortValue(component, currency),
                    style: TextStyle(
                      color: theme.themeColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends ConsumerWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.textColor.withAlpha(145),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

const _componentTypes = [
  "fixed",
  "hourly",
  "commission",
  "milestone",
  "per_unit",
  "per_project",
  "bonus",
  "deduction",
  "reimbursement",
  "custom",
];

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

String _componentDescription(
  CompensationComponentModel component,
  String currency,
) {
  if (component.isFixed) {
    return "${component.amount.toStringAsFixed(2)} $currency";
  }
  if (component.isHourly) {
    final source = component.requiresTimeEntries
        ? "requires_time_entries".tr
        : "${component.expectedHoursPerPeriod.toStringAsFixed(2)} h";
    return "${component.hourlyRate.toStringAsFixed(4)} $currency/h • $source";
  }
  if (component.calculationMethod == "percentage") {
    return "${component.percentageRate.toStringAsFixed(4)}% • "
        "${"commission_basis_${component.commissionBasis}".tr} • "
        "${component.eventType}";
  }
  if (component.calculationMethod == "per_unit") {
    return "${component.unitRate.toStringAsFixed(4)} $currency/u • "
        "${component.eventType}";
  }
  return "${component.fixedAmount.toStringAsFixed(2)} $currency • "
      "${component.eventType}";
}

String _componentShortValue(
  CompensationComponentModel component,
  String currency,
) {
  if (component.isFixed) {
    return "${component.amount.toStringAsFixed(0)} $currency";
  }
  if (component.isHourly) {
    return "${component.hourlyRate.toStringAsFixed(0)} $currency/h";
  }
  if (component.calculationMethod == "percentage") {
    return "${component.percentageRate.toStringAsFixed(2)}%";
  }
  if (component.calculationMethod == "per_unit") {
    return "${component.unitRate.toStringAsFixed(2)}/u";
  }
  return "${component.fixedAmount.toStringAsFixed(0)} $currency";
}

double? _parseNumber(String value) {
  final normalized = value.trim().replaceAll(",", ".");
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}

bool _isIsoDate(String value) {
  if (!RegExp(r"^\d{4}-\d{2}-\d{2}$").hasMatch(value)) {
    return false;
  }
  final parsed = DateTime.tryParse(value);
  return parsed != null && _formatDate(parsed) == value;
}

String _formatDate(DateTime value) {
  return "${value.year.toString().padLeft(4, "0")}-"
      "${value.month.toString().padLeft(2, "0")}-"
      "${value.day.toString().padLeft(2, "0")}";
}
