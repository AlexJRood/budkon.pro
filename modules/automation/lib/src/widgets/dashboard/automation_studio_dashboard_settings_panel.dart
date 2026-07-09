import 'package:flutter/material.dart';

import '../../config/automation_studio_config.dart';

class AutomationStudioDashboardSettingsPanel extends StatefulWidget {
  final Map<String, dynamic> settings;
  final ValueChanged<Map<String, dynamic>> onSettingsChanged;

  const AutomationStudioDashboardSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<AutomationStudioDashboardSettingsPanel> createState() =>
      _AutomationStudioDashboardSettingsPanelState();
}

class _AutomationStudioDashboardSettingsPanelState
    extends State<AutomationStudioDashboardSettingsPanel> {
  late Map<String, dynamic> _settings;
  late final TextEditingController _companyIdController;
  late final TextEditingController _ownerIdController;
  late final TextEditingController _dashboardIdController;
  late final TextEditingController _dashboardNameController;
  late final TextEditingController _maxItemsController;

  @override
  void initState() {
    super.initState();
    _settings = Map<String, dynamic>.from(widget.settings);
    _companyIdController = TextEditingController(text: _settings['companyId']?.toString() ?? '');
    _ownerIdController = TextEditingController(text: _settings['ownerId']?.toString() ?? '');
    _dashboardIdController = TextEditingController(text: _settings['dashboardId']?.toString() ?? '');
    _dashboardNameController = TextEditingController(text: _settings['dashboardName']?.toString() ?? '');
    _maxItemsController = TextEditingController(text: (_settings['maxItems'] ?? 5).toString());
  }

  @override
  void dispose() {
    _companyIdController.dispose();
    _ownerIdController.dispose();
    _dashboardIdController.dispose();
    _dashboardNameController.dispose();
    _maxItemsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = automationColors(context);
    final mode = (_settings['mode'] ?? 'overview').toString();
    final scopeType = (_settings['scopeType'] ?? 'auto').toString();
    final status = (_settings['workflowStatus'] ?? 'all').toString();
    final compact = _settings['compact'] == true;
    final showHeader = _settings['showHeader'] is bool ? _settings['showHeader'] as bool : true;

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          'Automation dashboard settings',
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 14),
        _DropdownField(
          label: 'Mode',
          value: mode,
          items: const {
            'overview': 'Overview',
            'workflows': 'Workflows',
            'history': 'History',
            'approvals': 'Approvals',
          },
          onChanged: (value) => _set('mode', value),
        ),
        const SizedBox(height: 10),
        _DropdownField(
          label: 'Scope',
          value: scopeType,
          items: const {
            'auto': 'Auto from context',
            'company': 'Company',
            'user': 'User',
          },
          onChanged: (value) => _set('scopeType', value),
        ),
        const SizedBox(height: 10),
        _DropdownField(
          label: 'Workflow status',
          value: status,
          items: const {
            'all': 'All',
            'active': 'Active',
            'draft': 'Draft',
            'paused': 'Paused',
            'archived': 'Archived',
          },
          onChanged: (value) => _set('workflowStatus', value),
        ),
        const SizedBox(height: 12),
        _TextField(
          label: 'Company ID',
          controller: _companyIdController,
          keyboardType: TextInputType.number,
          onChanged: (value) => _setNullableInt('companyId', value),
        ),
        const SizedBox(height: 10),
        _TextField(
          label: 'Owner/User ID',
          controller: _ownerIdController,
          keyboardType: TextInputType.number,
          onChanged: (value) => _setNullableInt('ownerId', value),
        ),
        const SizedBox(height: 10),
        _TextField(
          label: 'Dashboard ID',
          controller: _dashboardIdController,
          onChanged: (value) => _setNullableString('dashboardId', value),
        ),
        const SizedBox(height: 10),
        _TextField(
          label: 'Dashboard name',
          controller: _dashboardNameController,
          onChanged: (value) => _setNullableString('dashboardName', value),
        ),
        const SizedBox(height: 10),
        _TextField(
          label: 'Max items',
          controller: _maxItemsController,
          keyboardType: TextInputType.number,
          onChanged: (value) => _set('maxItems', int.tryParse(value) ?? 5),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          value: compact,
          onChanged: (value) => _set('compact', value),
          contentPadding: EdgeInsets.zero,
          title: const Text('Compact mode'),
        ),
        SwitchListTile.adaptive(
          value: showHeader,
          onChanged: (value) => _set('showHeader', value),
          contentPadding: EdgeInsets.zero,
          title: const Text('Show header'),
        ),
      ],
    );
  }

  void _set(String key, dynamic value) {
    setState(() {
      _settings[key] = value;
    });
    widget.onSettingsChanged(Map<String, dynamic>.from(_settings));
  }

  void _setNullableString(String key, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      setState(() => _settings.remove(key));
    } else {
      setState(() => _settings[key] = normalized);
    }
    widget.onSettingsChanged(Map<String, dynamic>.from(_settings));
  }

  void _setNullableInt(String key, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      setState(() => _settings.remove(key));
    } else {
      final parsed = int.tryParse(normalized);
      if (parsed != null) {
        setState(() => _settings[key] = parsed);
      }
    }
    widget.onSettingsChanged(Map<String, dynamic>.from(_settings));
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: items.containsKey(value) ? value : items.keys.first,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  const _TextField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}
