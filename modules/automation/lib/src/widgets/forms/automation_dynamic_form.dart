import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

class AutomationFormVariable {
  final String label;
  final String token;
  final String description;
  final IconData icon;

  const AutomationFormVariable({
    required this.label,
    required this.token,
    this.description = '',
    this.icon = Icons.data_object_rounded,
  });
}

class AutomationDynamicForm extends StatelessWidget {
  final String title;
  final Map<String, dynamic> schema;
  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final ThemeColors theme;
  final List<AutomationFormVariable> variables;
  final bool dense;
  final bool showEmptyState;

  const AutomationDynamicForm({
    super.key,
    required this.title,
    required this.schema,
    required this.value,
    required this.onChanged,
    required this.theme,
    this.variables = const [],
    this.dense = false,
    this.showEmptyState = true,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedSchema = _normalizeObjectSchema(schema);
    final properties = _asMap(normalizedSchema['properties']);

    if (properties.isEmpty) {
      if (!showEmptyState) return const SizedBox.shrink();

      return _FriendlyEmptyConfig(
        theme: theme,
        title: title,
        message: 'This block does not require extra configuration.',
      );
    }

    final requiredFields = _asStringList(normalizedSchema['required']);
    final orderedKeys = _orderedPropertyKeys(normalizedSchema, properties);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.trim().isNotEmpty) ...[
          _SectionTitle(
            theme: theme,
            icon: Icons.tune_rounded,
            title: title,
          ),
          const SizedBox(height: 10),
        ],
        for (final key in orderedKeys) ...[
          _DynamicField(
            fieldKey: key,
            schema: _asMap(properties[key]),
            requiredField: requiredFields.contains(key),
            value: value[key],
            theme: theme,
            variables: variables,
            dense: dense,
            onChanged: (next) {
              final patched = Map<String, dynamic>.from(value);

              if (next == null) {
                patched.remove(key);
              } else {
                patched[key] = next;
              }

              onChanged(patched);
            },
          ),
          SizedBox(height: dense ? 10 : 12),
        ],
      ],
    );
  }
}

class AutomationAvailableInputPanel extends StatelessWidget {
  final ThemeColors theme;
  final List<AutomationFormVariable> variables;
  final ValueChanged<String>? onInsert;

  const AutomationAvailableInputPanel({
    super.key,
    required this.theme,
    required this.variables,
    this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    if (variables.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.themeColor.withAlpha(58)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.input_rounded, color: theme.themeColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Available input',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Click a chip to use this value in text fields.',
            style: TextStyle(
              color: theme.textColor.withAlpha(145),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final variable in variables)
                Tooltip(
                  message: variable.description.isEmpty
                      ? variable.token
                      : '${variable.description}\n${variable.token}',
                  child: ActionChip(
                    avatar: Icon(variable.icon, size: 15, color: theme.themeColor),
                    label: Text(variable.label),
                    onPressed: onInsert == null ? null : () => onInsert!(variable.token),
                    labelStyle: TextStyle(
                      color: theme.textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    backgroundColor: theme.dashboardContainer,
                    side: BorderSide(color: theme.dashboardBoarder.withAlpha(150)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AutomationConditionBuilder extends StatefulWidget {
  final ThemeColors theme;
  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final List<AutomationFormVariable> variables;

  const AutomationConditionBuilder({
    super.key,
    required this.theme,
    required this.value,
    required this.onChanged,
    this.variables = const [],
  });

  @override
  State<AutomationConditionBuilder> createState() => _AutomationConditionBuilderState();
}

class _AutomationConditionBuilderState extends State<AutomationConditionBuilder> {
  late String mode;
  late List<Map<String, dynamic>> rows;

  @override
  void initState() {
    super.initState();
    _load(widget.value);
  }

  @override
  void didUpdateWidget(covariant AutomationConditionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _load(widget.value);
    }
  }

  void _load(Map<String, dynamic> value) {
    if (value['any'] is List) {
      mode = 'any';
      rows = _asMapList(value['any']);
    } else {
      mode = 'all';
      rows = _asMapList(value['all']);
    }

    if (rows.isEmpty) {
      rows = [
        {
          'path': '',
          'op': 'eq',
          'value': '',
        }
      ];
    }
  }

  void _emit() {
    widget.onChanged({
      mode: rows,
    });
  }

  void _patchRow(int index, String key, dynamic value) {
    setState(() {
      rows[index] = {
        ...rows[index],
        key: value,
      };
    });
    _emit();
  }

  void _addRow() {
    setState(() {
      rows.add({
        'path': '',
        'op': 'eq',
        'value': '',
      });
    });
    _emit();
  }

  void _removeRow(int index) {
    setState(() {
      rows.removeAt(index);
      if (rows.isEmpty) {
        rows.add({
          'path': '',
          'op': 'eq',
          'value': '',
        });
      }
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final operators = const [
      'eq',
      'neq',
      'contains',
      'not_contains',
      'gt',
      'gte',
      'lt',
      'lte',
      'exists',
      'empty',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          theme: widget.theme,
          icon: Icons.rule_rounded,
          title: 'Conditions',
        ),
        const SizedBox(height: 10),
        CoreDropdown<String>(
          label: 'Match mode',
          value: mode,
          options: const ['all', 'any'],
          onChanged: (next) {
            if (next == null) return;

            setState(() => mode = next);
            _emit();
          },
          display: (item) => item == 'all' ? 'All conditions must match' : 'Any condition can match',
          prefixIcon: const Icon(Icons.call_split_rounded),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < rows.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.theme.dashboardContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.theme.dashboardBoarder.withAlpha(150)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TemplateTextField(
                        theme: widget.theme,
                        label: 'Input path',
                        value: rows[i]['path']?.toString() ?? '',
                        variables: widget.variables,
                        prefixIcon: const Icon(Icons.account_tree_rounded),
                        onChanged: (value) => _patchRow(i, 'path', value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 132,
                      child: CoreDropdown<String>(
                        label: 'Operator',
                        value: operators.contains(rows[i]['op']) ? rows[i]['op']?.toString() : 'eq',
                        options: operators,
                        onChanged: (value) => _patchRow(i, 'op', value ?? 'eq'),
                        display: _operatorLabel,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove condition',
                      onPressed: rows.length <= 1 ? null : () => _removeRow(i),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                if (!{'exists', 'empty'}.contains(rows[i]['op'])) ...[
                  const SizedBox(height: 10),
                  _TemplateTextField(
                    theme: widget.theme,
                    label: 'Compare with',
                    value: rows[i]['value']?.toString() ?? '',
                    variables: widget.variables,
                    prefixIcon: const Icon(Icons.compare_arrows_rounded),
                    onChanged: (value) => _patchRow(i, 'value', value),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add condition'),
          ),
        ),
      ],
    );
  }

  String _operatorLabel(String op) {
    switch (op) {
      case 'eq':
        return 'Equals';
      case 'neq':
        return 'Not equal';
      case 'contains':
        return 'Contains';
      case 'not_contains':
        return 'Not contains';
      case 'gt':
        return 'Greater';
      case 'gte':
        return 'Greater/equal';
      case 'lt':
        return 'Lower';
      case 'lte':
        return 'Lower/equal';
      case 'exists':
        return 'Exists';
      case 'empty':
        return 'Empty';
      default:
        return op;
    }
  }
}

class AutomationDelayForm extends StatefulWidget {
  final ThemeColors theme;
  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const AutomationDelayForm({
    super.key,
    required this.theme,
    required this.value,
    required this.onChanged,
  });

  @override
  State<AutomationDelayForm> createState() => _AutomationDelayFormState();
}

class _AutomationDelayFormState extends State<AutomationDelayForm> {
  late final TextEditingController amountController;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(
      text: (widget.value['amount'] ?? 1).toString(),
    );
  }

  @override
  void didUpdateWidget(covariant AutomationDelayForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    final next = (widget.value['amount'] ?? 1).toString();
    if (oldWidget.value != widget.value && amountController.text != next) {
      amountController.text = next;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void _emit({int? amount, String? unit}) {
    widget.onChanged({
      'amount': amount ?? int.tryParse(amountController.text.trim()) ?? 1,
      'unit': unit ?? widget.value['unit']?.toString() ?? 'minutes',
    });
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.value['unit']?.toString() ?? 'minutes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          theme: widget.theme,
          icon: Icons.schedule_rounded,
          title: 'Delay',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CoreTextField(
                label: 'Amount',
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefixIcon: const Icon(Icons.timer_outlined),
                onChanged: (value) => _emit(amount: int.tryParse(value.trim()) ?? 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CoreDropdown<String>(
                label: 'Unit',
                value: ['seconds', 'minutes', 'hours', 'days'].contains(unit) ? unit : 'minutes',
                options: const ['seconds', 'minutes', 'hours', 'days'],
                onChanged: (value) => _emit(unit: value ?? 'minutes'),
                prefixIcon: const Icon(Icons.av_timer_rounded),
                display: (value) {
                  switch (value) {
                    case 'seconds':
                      return 'Seconds';
                    case 'minutes':
                      return 'Minutes';
                    case 'hours':
                      return 'Hours';
                    case 'days':
                      return 'Days';
                    default:
                      return value;
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DynamicField extends StatelessWidget {
  final String fieldKey;
  final Map<String, dynamic> schema;
  final bool requiredField;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final ThemeColors theme;
  final List<AutomationFormVariable> variables;
  final bool dense;

  const _DynamicField({
    required this.fieldKey,
    required this.schema,
    required this.requiredField,
    required this.value,
    required this.onChanged,
    required this.theme,
    required this.variables,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final type = _schemaType(schema, value);
    final label = _fieldTitle(fieldKey, schema, requiredField);
    final description = _fieldDescription(schema);

    if (_enumOptions(schema).isNotEmpty) {
      final options = _enumOptions(schema);
      final stringValue = value?.toString();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CoreDropdown<String>(
            label: label,
            value: options.contains(stringValue) ? stringValue : null,
            options: options,
            hintText: _hint(schema),
            onChanged: onChanged,
            display: (option) => _enumLabel(schema, option),
          ),
          if (description.isNotEmpty) _Helper(theme: theme, text: description),
        ],
      );
    }

    switch (type) {
      case 'boolean':
        return _BooleanField(
          label: label,
          description: description,
          value: _asBool(value),
          theme: theme,
          onChanged: onChanged,
        );

      case 'integer':
        return _DynamicNumberField(
          label: label,
          description: description,
          value: value,
          integerOnly: true,
          theme: theme,
          onChanged: (text) => onChanged(int.tryParse(text.trim()) ?? 0),
        );

      case 'number':
        return _DynamicNumberField(
          label: label,
          description: description,
          value: value,
          integerOnly: false,
          theme: theme,
          onChanged: (text) => onChanged(double.tryParse(text.trim().replaceAll(',', '.')) ?? 0.0),
        );

      case 'object':
        return _NestedObjectField(
          label: label,
          description: description,
          schema: schema,
          value: _asMap(value),
          theme: theme,
          variables: variables,
          onChanged: onChanged,
        );

      case 'array':
        return _ArrayField(
          label: label,
          description: description,
          schema: schema,
          value: value,
          theme: theme,
          variables: variables,
          onChanged: onChanged,
        );

      case 'string':
      default:
        return _TemplateTextField(
          theme: theme,
          label: label,
          value: value?.toString() ?? '',
          description: description,
          variables: variables,
          multiline: _isMultiline(fieldKey, schema),
          obscureText: _isSecret(fieldKey, schema),
          keyboardType: _keyboardType(fieldKey, schema),
          prefixIcon: _fieldIcon(fieldKey, schema),
          hintText: _hint(schema),
          onChanged: onChanged,
        );
    }
  }
}

class _TemplateTextField extends StatefulWidget {
  final ThemeColors theme;
  final String label;
  final String value;
  final String description;
  final ValueChanged<String> onChanged;
  final List<AutomationFormVariable> variables;
  final bool multiline;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final String? hintText;

  const _TemplateTextField({
    required this.theme,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description = '',
    this.variables = const [],
    this.multiline = false,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.hintText,
  });

  @override
  State<_TemplateTextField> createState() => _TemplateTextFieldState();
}

class _TemplateTextFieldState extends State<_TemplateTextField> {
  late final TextEditingController controller;
  bool focused = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TemplateTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!focused && oldWidget.value != widget.value && controller.text != widget.value) {
      controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _insertToken(String token) {
    final selection = controller.selection;
    final text = controller.text;

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final next = text.replaceRange(start, end, token);
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + token.length),
    );

    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) => focused = value,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CoreTextField(
            label: widget.label,
            controller: controller,
            minLines: widget.multiline ? 4 : 1,
            maxLines: widget.multiline ? 12 : 1,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType ?? (widget.multiline ? TextInputType.multiline : TextInputType.text),
            textInputAction: widget.multiline ? TextInputAction.newline : TextInputAction.done,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.variables.isEmpty
                ? null
                : PopupMenuButton<String>(
                    tooltip: 'Insert input variable',
                    icon: const Icon(Icons.add_link_rounded),
                    onSelected: _insertToken,
                    itemBuilder: (context) => [
                      for (final variable in widget.variables)
                        PopupMenuItem(
                          value: variable.token,
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(variable.icon, size: 18),
                            title: Text(variable.label),
                            subtitle: Text(variable.token),
                          ),
                        ),
                    ],
                  ),
            onChanged: widget.onChanged,
          ),
          if (widget.hintText?.trim().isNotEmpty == true)
            _Helper(theme: widget.theme, text: widget.hintText!),
          if (widget.description.trim().isNotEmpty)
            _Helper(theme: widget.theme, text: widget.description),
          if (widget.variables.isNotEmpty && widget.multiline) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final variable in widget.variables.take(8))
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(variable.icon, size: 14, color: widget.theme.themeColor),
                    label: Text(variable.label),
                    onPressed: () => _insertToken(variable.token),
                    labelStyle: TextStyle(
                      fontSize: 10.5,
                      color: widget.theme.textColor,
                      fontWeight: FontWeight.w800,
                    ),
                    backgroundColor: widget.theme.dashboardContainer,
                    side: BorderSide(color: widget.theme.dashboardBoarder.withAlpha(150)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DynamicNumberField extends StatefulWidget {
  final String label;
  final String description;
  final dynamic value;
  final bool integerOnly;
  final ThemeColors theme;
  final ValueChanged<String> onChanged;

  const _DynamicNumberField({
    required this.label,
    required this.description,
    required this.value,
    required this.integerOnly,
    required this.theme,
    required this.onChanged,
  });

  @override
  State<_DynamicNumberField> createState() => _DynamicNumberFieldState();
}

class _DynamicNumberFieldState extends State<_DynamicNumberField> {
  late final TextEditingController controller;
  bool focused = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _DynamicNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final next = widget.value?.toString() ?? '';
    if (!focused && oldWidget.value != widget.value && controller.text != next) {
      controller.text = next;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) => focused = value,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CoreTextField(
            label: widget.label,
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: widget.integerOnly
                ? [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))]
                : [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*[,.]?\d*'))],
            prefixIcon: const Icon(Icons.numbers_rounded),
            onChanged: widget.onChanged,
          ),
          if (widget.description.isNotEmpty)
            _Helper(theme: widget.theme, text: widget.description),
        ],
      ),
    );
  }
}

class _BooleanField extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ThemeColors theme;

  const _BooleanField({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(150)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          label,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: description.isEmpty
            ? null
            : Text(
                description,
                style: TextStyle(color: theme.textColor.withAlpha(145)),
              ),
      ),
    );
  }
}

class _NestedObjectField extends StatelessWidget {
  final String label;
  final String description;
  final Map<String, dynamic> schema;
  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final ThemeColors theme;
  final List<AutomationFormVariable> variables;

  const _NestedObjectField({
    required this.label,
    required this.description,
    required this.schema,
    required this.value,
    required this.onChanged,
    required this.theme,
    required this.variables,
  });

  @override
  Widget build(BuildContext context) {
    final objectSchema = _normalizeObjectSchema(schema);
    final properties = _asMap(objectSchema['properties']);

    if (properties.isEmpty) {
      return _KeyValueObjectField(
        label: label,
        description: description,
        value: value,
        theme: theme,
        onChanged: onChanged,
      );
    }

    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: _SectionTitle(
        theme: theme,
        icon: Icons.folder_open_rounded,
        title: label,
      ),
      subtitle: description.isEmpty
          ? null
          : Text(
              description,
              style: TextStyle(color: theme.textColor.withAlpha(145)),
            ),
      children: [
        AutomationDynamicForm(
          title: '',
          schema: objectSchema,
          value: value,
          onChanged: onChanged,
          theme: theme,
          variables: variables,
          dense: true,
          showEmptyState: false,
        ),
      ],
    );
  }
}

class _ArrayField extends StatelessWidget {
  final String label;
  final String description;
  final Map<String, dynamic> schema;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final ThemeColors theme;
  final List<AutomationFormVariable> variables;

  const _ArrayField({
    required this.label,
    required this.description,
    required this.schema,
    required this.value,
    required this.onChanged,
    required this.theme,
    required this.variables,
  });

  @override
  Widget build(BuildContext context) {
    final itemsSchema = _asMap(schema['items']);
    final itemType = _schemaType(itemsSchema, null);

    if (itemType == 'object') {
      return _ObjectListField(
        label: label,
        description: description,
        schema: itemsSchema,
        value: _asMapList(value),
        theme: theme,
        variables: variables,
        onChanged: onChanged,
      );
    }

    return _StringListField(
      label: label,
      description: description,
      value: _asStringList(value),
      theme: theme,
      onChanged: onChanged,
    );
  }
}

class _StringListField extends StatefulWidget {
  final String label;
  final String description;
  final List<String> value;
  final ValueChanged<List<String>> onChanged;
  final ThemeColors theme;

  const _StringListField({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  State<_StringListField> createState() => _StringListFieldState();
}

class _StringListFieldState extends State<_StringListField> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final next = [...widget.value, text];
    controller.clear();
    widget.onChanged(next);
  }

  void _remove(String value) {
    final next = [...widget.value]..remove(value);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoreTextField(
          label: widget.label,
          controller: controller,
          prefixIcon: const Icon(Icons.list_rounded),
          suffixIcon: IconButton(
            tooltip: 'Add',
            onPressed: _add,
            icon: const Icon(Icons.add_rounded),
          ),
          onSubmitted: (_) => _add(),
        ),
        if (widget.description.isNotEmpty)
          _Helper(theme: widget.theme, text: widget.description),
        const SizedBox(height: 8),
        if (widget.value.isEmpty)
          Text(
            'No items yet.',
            style: TextStyle(
              color: widget.theme.textColor.withAlpha(140),
              fontSize: 11,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in widget.value)
                Chip(
                  label: Text(item),
                  onDeleted: () => _remove(item),
                  backgroundColor: widget.theme.dashboardContainer,
                  side: BorderSide(color: widget.theme.dashboardBoarder.withAlpha(150)),
                ),
            ],
          ),
      ],
    );
  }
}

class _ObjectListField extends StatelessWidget {
  final String label;
  final String description;
  final Map<String, dynamic> schema;
  final List<Map<String, dynamic>> value;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final ThemeColors theme;
  final List<AutomationFormVariable> variables;

  const _ObjectListField({
    required this.label,
    required this.description,
    required this.schema,
    required this.value,
    required this.onChanged,
    required this.theme,
    required this.variables,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      title: _SectionTitle(
        theme: theme,
        icon: Icons.dynamic_form_rounded,
        title: label,
      ),
      subtitle: description.isEmpty
          ? null
          : Text(description, style: TextStyle(color: theme.textColor.withAlpha(145))),
      children: [
        for (var i = 0; i < value.length; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dashboardBoarder.withAlpha(150)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Item ${i + 1}',
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove item',
                      onPressed: () {
                        final next = [...value]..removeAt(i);
                        onChanged(next);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                AutomationDynamicForm(
                  title: '',
                  schema: schema,
                  value: value[i],
                  onChanged: (nextItem) {
                    final next = [...value];
                    next[i] = nextItem;
                    onChanged(next);
                  },
                  theme: theme,
                  variables: variables,
                  dense: true,
                  showEmptyState: false,
                ),
              ],
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () {
              onChanged([...value, _defaultsFromSchema(schema)]);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add item'),
          ),
        ),
      ],
    );
  }
}

class _KeyValueObjectField extends StatefulWidget {
  final String label;
  final String description;
  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final ThemeColors theme;

  const _KeyValueObjectField({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  State<_KeyValueObjectField> createState() => _KeyValueObjectFieldState();
}

class _KeyValueObjectFieldState extends State<_KeyValueObjectField> {
  late List<_KeyValueRow> rows;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _KeyValueObjectField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) _load();
  }

  void _load() {
    rows = widget.value.entries
        .map((entry) => _KeyValueRow(entry.key, entry.value?.toString() ?? ''))
        .toList();

    if (rows.isEmpty) rows.add(_KeyValueRow('', ''));
  }

  void _emit() {
    final out = <String, dynamic>{};

    for (final row in rows) {
      final key = row.keyController.text.trim();
      if (key.isEmpty) continue;
      out[key] = row.valueController.text;
    }

    widget.onChanged(out);
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: false,
      tilePadding: EdgeInsets.zero,
      title: _SectionTitle(
        theme: widget.theme,
        icon: Icons.table_rows_rounded,
        title: widget.label,
      ),
      subtitle: widget.description.isEmpty
          ? null
          : Text(widget.description, style: TextStyle(color: widget.theme.textColor.withAlpha(145))),
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: CoreTextField(
                  label: 'Key',
                  controller: rows[i].keyController,
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CoreTextField(
                  label: 'Value',
                  controller: rows[i].valueController,
                  onChanged: (_) => _emit(),
                ),
              ),
              IconButton(
                onPressed: rows.length == 1
                    ? null
                    : () {
                        setState(() => rows.removeAt(i));
                        _emit();
                      },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() => rows.add(_KeyValueRow('', '')));
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add field'),
          ),
        ),
      ],
    );
  }
}

class _KeyValueRow {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _KeyValueRow(String key, String value)
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);
}

class _FriendlyEmptyConfig extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final String message;

  const _FriendlyEmptyConfig({
    required this.theme,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dashboardBoarder.withAlpha(130)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: theme.themeColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.theme,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: theme.themeColor, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _Helper extends StatelessWidget {
  final ThemeColors theme;
  final String text;

  const _Helper({
    required this.theme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 2),
      child: Text(
        text,
        style: TextStyle(
          color: theme.textColor.withAlpha(145),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Map<String, dynamic> automationDefaultsFromSchema(Map<String, dynamic> schema) {
  return _defaultsFromSchema(schema);
}

Map<String, dynamic> _defaultsFromSchema(Map<String, dynamic> schema) {
  final normalized = _normalizeObjectSchema(schema);
  final out = <String, dynamic>{};
  final properties = _asMap(normalized['properties']);

  for (final entry in properties.entries) {
    final key = entry.key;
    final fieldSchema = _asMap(entry.value);

    if (fieldSchema.containsKey('default')) {
      out[key] = fieldSchema['default'];
      continue;
    }

    final enumValues = _enumOptions(fieldSchema);
    if (enumValues.isNotEmpty) {
      out[key] = enumValues.first;
      continue;
    }

    final type = _schemaType(fieldSchema, null);
    if (type == 'object') {
      out[key] = _defaultsFromSchema(fieldSchema);
    } else if (type == 'array') {
      out[key] = [];
    } else if (type == 'boolean') {
      out[key] = false;
    }
  }

  return out;
}

Map<String, dynamic> _normalizeObjectSchema(Map<String, dynamic> schema) {
  if (schema.isEmpty) return const {};

  if (schema['type'] == 'object' || schema['properties'] is Map) {
    return schema;
  }

  final properties = <String, dynamic>{};

  for (final entry in schema.entries) {
    if (entry.value is Map) {
      properties[entry.key] = entry.value;
    }
  }

  if (properties.isNotEmpty) {
    return {
      'type': 'object',
      'properties': properties,
    };
  }

  return schema;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
}

List<String> _asStringList(dynamic value) {
  if (value == null) return const [];

  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) return const [];

  return raw
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final raw = value?.toString().trim().toLowerCase() ?? '';
  if (['true', '1', 'yes', 'tak'].contains(raw)) return true;
  if (['false', '0', 'no', 'nie'].contains(raw)) return false;

  return false;
}

List<String> _enumOptions(Map<String, dynamic> schema) {
  final raw = schema['enum'] ?? schema['x-options'] ?? schema['options'];
  return _asStringList(raw);
}

String _enumLabel(Map<String, dynamic> schema, String option) {
  final labels = _asMap(schema['x-enum-labels'] ?? schema['enum_labels']);

  if (labels[option] != null) return labels[option].toString();

  return _humanize(option);
}

List<String> _orderedPropertyKeys(
  Map<String, dynamic> schema,
  Map<String, dynamic> properties,
) {
  final order = _asStringList(schema['ui:order'] ?? schema['x-ui-order']);
  final keys = <String>[];

  for (final key in order) {
    if (properties.containsKey(key)) keys.add(key);
  }

  for (final key in properties.keys) {
    if (!keys.contains(key)) keys.add(key);
  }

  return keys;
}

String _schemaType(Map<String, dynamic> schema, dynamic value) {
  final type = schema['type'];

  if (type is String) {
    if (type == 'number' || type == 'integer' || type == 'boolean' || type == 'object' || type == 'array') {
      return type;
    }
    return 'string';
  }

  if (type is List) {
    for (final item in type) {
      final normalized = item?.toString();
      if (normalized != null && normalized != 'null') return normalized;
    }
  }

  if (schema['properties'] is Map) return 'object';
  if (schema['items'] is Map) return 'array';

  if (value is bool) return 'boolean';
  if (value is int) return 'integer';
  if (value is num) return 'number';
  if (value is Map) return 'object';
  if (value is List) return 'array';

  return 'string';
}

String _fieldTitle(String key, Map<String, dynamic> schema, bool required) {
  final raw = schema['title'] ?? schema['label'] ?? schema['x-label'];
  final base = raw?.toString().trim().isNotEmpty == true ? raw.toString() : _humanize(key);
  return required ? '$base *' : base;
}

String _fieldDescription(Map<String, dynamic> schema) {
  return (schema['description'] ?? schema['helpText'] ?? schema['x-help'] ?? '').toString();
}

String? _hint(Map<String, dynamic> schema) {
  final raw = schema['placeholder'] ?? schema['x-placeholder'] ?? schema['hint'];
  final text = raw?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

bool _isMultiline(String key, Map<String, dynamic> schema) {
  final widget = (schema['x-ui-widget'] ?? schema['widget'] ?? '').toString();
  final format = (schema['format'] ?? '').toString();
  final lowered = key.toLowerCase();

  return widget == 'textarea' ||
      format == 'textarea' ||
      lowered.contains('body') ||
      lowered.contains('message') ||
      lowered.contains('prompt') ||
      lowered.contains('description') ||
      lowered.contains('html');
}

bool _isSecret(String key, Map<String, dynamic> schema) {
  final widget = (schema['x-ui-widget'] ?? schema['widget'] ?? '').toString();
  final format = (schema['format'] ?? '').toString();
  final lowered = key.toLowerCase();

  return widget == 'password' ||
      format == 'password' ||
      lowered.contains('password') ||
      lowered.contains('secret') ||
      lowered.contains('token') ||
      lowered.contains('api_key');
}

TextInputType? _keyboardType(String key, Map<String, dynamic> schema) {
  final format = (schema['format'] ?? '').toString();
  final lowered = key.toLowerCase();

  if (format == 'email' || lowered.contains('email')) return TextInputType.emailAddress;
  if (format == 'uri' || format == 'url' || lowered.contains('url')) return TextInputType.url;
  if (format == 'date-time' || format == 'date') return TextInputType.datetime;

  return null;
}

Widget? _fieldIcon(String key, Map<String, dynamic> schema) {
  final format = (schema['format'] ?? '').toString();
  final lowered = key.toLowerCase();

  if (format == 'email' || lowered.contains('email') || lowered == 'to') {
    return const Icon(Icons.alternate_email_rounded);
  }

  if (format == 'uri' || format == 'url' || lowered.contains('url')) {
    return const Icon(Icons.link_rounded);
  }

  if (lowered.contains('subject') || lowered.contains('title')) {
    return const Icon(Icons.title_rounded);
  }

  if (lowered.contains('body') || lowered.contains('message')) {
    return const Icon(Icons.notes_rounded);
  }

  if (lowered.contains('method')) {
    return const Icon(Icons.http_rounded);
  }

  if (lowered.contains('key')) {
    return const Icon(Icons.key_rounded);
  }

  return null;
}

String _humanize(String value) {
  final normalized = value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAll('.', ' ')
      .trim();

  if (normalized.isEmpty) return value;

  return normalized[0].toUpperCase() + normalized.substring(1);
}
