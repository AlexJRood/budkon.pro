import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

class AutomationNotificationVariable {
  final String label;
  final String token;
  final IconData icon;

  const AutomationNotificationVariable({
    required this.label,
    required this.token,
    this.icon = Icons.data_object_rounded,
  });
}

class AutomationNodeNotificationsForm extends StatefulWidget {
  final String nodeId;
  final String nodeType;
  final ThemeColors theme;
  final dynamic value;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final List<AutomationNotificationVariable> variables;

  const AutomationNodeNotificationsForm({
    super.key,
    required this.nodeId,
    required this.nodeType,
    required this.theme,
    required this.value,
    required this.onChanged,
    this.variables = const [],
  });

  @override
  State<AutomationNodeNotificationsForm> createState() => _AutomationNodeNotificationsFormState();
}

class _AutomationNodeNotificationsFormState extends State<AutomationNodeNotificationsForm> {
  late List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    items = _normalize(widget.value);
  }

  @override
  void didUpdateWidget(covariant AutomationNodeNotificationsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodeId != widget.nodeId || oldWidget.value != widget.value) {
      items = _normalize(widget.value);
    }
  }

  List<Map<String, dynamic>> _normalize(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (raw is Map && raw.isNotEmpty) return [Map<String, dynamic>.from(raw)];
    return [];
  }

  void _emit() => widget.onChanged(items.map((e) => Map<String, dynamic>.from(e)).toList());

  void _add() {
    setState(() {
      items.add({
        'id': 'notification_${DateTime.now().microsecondsSinceEpoch}',
        'enabled': true,
        'timing': _defaultTiming(widget.nodeType),
        'channels': ['in_app'],
        'recipients': [
          {'type': 'actor'},
        ],
        'title': _defaultTitle(widget.nodeType),
        'message': 'Block {{node.label}} changed state in {{workflow.name}}.',
        'icon': 'notifications',
        'image_url': '',
        'priority': 'normal',
        'link_url': '',
        'include_context': true,
        'delay': {'amount': 0, 'unit': 'minutes'},
        'cooldown_minutes': 0,
        'throttle_key': '',
        'conditions': {'all': []},
      });
    });
    _emit();
  }

  void _patch(int i, String key, dynamic value) {
    setState(() => items[i] = {...items[i], key: value});
    _emit();
  }

  void _remove(int i) {
    setState(() => items.removeAt(i));
    _emit();
  }

  void _duplicate(int i) {
    setState(() {
      final copy = Map<String, dynamic>.from(items[i]);
      items.insert(i + 1, {
        ...copy,
        'id': 'notification_${DateTime.now().microsecondsSinceEpoch}',
        'title': '${copy['title'] ?? 'Notification'} copy',
      });
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: t.dashboardContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.dashboardBoarder.withAlpha(150)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.notifications_active_rounded, color: t.themeColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Notifications',
                style: TextStyle(color: t.textColor, fontSize: 13, fontWeight: FontWeight.w900)),
          ),
          _Counter(theme: t, count: items.length),
        ]),
        const SizedBox(height: 7),
        Text(
          'Notify users, admins, teams, emails or webhooks when this block starts, succeeds, fails, waits or branches.',
          style: TextStyle(color: t.textColor.withAlpha(145), fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _Empty(theme: t, onAdd: _add)
        else ...[
          for (var i = 0; i < items.length; i++) ...[
            _NotificationCard(
              nodeType: widget.nodeType,
              theme: t,
              value: items[i],
              variables: widget.variables,
              onPatch: (k, v) => _patch(i, k, v),
              onRemove: () => _remove(i),
              onDuplicate: () => _duplicate(i),
            ),
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add notification'),
            ),
          ),
        ],
      ]),
    );
  }

  String _defaultTiming(String type) {
    if (type == 'approval') return 'approval_required';
    if (type == 'delay') return 'waiting';
    if (type == 'condition' || type == 'switch' || type == 'ai_prompt') return 'after_branch';
    return 'after_success';
  }

  String _defaultTitle(String type) {
    if (type == 'approval') return 'Approval required';
    if (type == 'delay') return 'Workflow is waiting';
    if (type == 'condition' || type == 'switch') return 'Workflow branch selected';
    if (type == 'ai_prompt') return 'Emma generated a result';
    return 'Automation step finished';
  }
}

class _NotificationCard extends StatefulWidget {
  final String nodeType;
  final ThemeColors theme;
  final Map<String, dynamic> value;
  final List<AutomationNotificationVariable> variables;
  final void Function(String key, dynamic value) onPatch;
  final VoidCallback onRemove;
  final VoidCallback onDuplicate;

  const _NotificationCard({
    required this.nodeType,
    required this.theme,
    required this.value,
    required this.variables,
    required this.onPatch,
    required this.onRemove,
    required this.onDuplicate,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  late TextEditingController title;
  late TextEditingController message;
  late TextEditingController icon;
  late TextEditingController imageUrl;
  late TextEditingController linkUrl;
  late TextEditingController cooldown;
  late TextEditingController throttle;
  late TextEditingController customEmail;
  late TextEditingController customUserId;
  late TextEditingController delayAmount;

  @override
  void initState() {
    super.initState();
    title = TextEditingController();
    message = TextEditingController();
    icon = TextEditingController();
    imageUrl = TextEditingController();
    linkUrl = TextEditingController();
    cooldown = TextEditingController();
    throttle = TextEditingController();
    customEmail = TextEditingController();
    customUserId = TextEditingController();
    delayAmount = TextEditingController();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _NotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _sync();
  }

  @override
  void dispose() {
    for (final c in [title, message, icon, imageUrl, linkUrl, cooldown, throttle, customEmail, customUserId, delayAmount]) {
      c.dispose();
    }
    super.dispose();
  }

  void _sync() {
    title.text = widget.value['title']?.toString() ?? '';
    message.text = widget.value['message']?.toString() ?? '';
    icon.text = widget.value['icon']?.toString() ?? 'notifications';
    imageUrl.text = widget.value['image_url']?.toString() ?? '';
    linkUrl.text = widget.value['link_url']?.toString() ?? '';
    cooldown.text = widget.value['cooldown_minutes']?.toString() ?? '0';
    throttle.text = widget.value['throttle_key']?.toString() ?? '';
    delayAmount.text = _delay['amount']?.toString() ?? '0';
  }

  Map<String, dynamic> get _delay => _asMap(widget.value['delay']);

  List<Map<String, dynamic>> get _recipients => _asMapList(widget.value['recipients']);

  List<String> get _channels => _asStringList(widget.value['channels']);

  void _patchDelay(String key, dynamic value) => widget.onPatch('delay', {..._delay, key: value});

  void _toggleChannel(String channel, bool selected) {
    final set = _channels.toSet();
    selected ? set.add(channel) : set.remove(channel);
    if (set.isEmpty) set.add('in_app');
    widget.onPatch('channels', set.toList());
  }

  void _toggleRecipient(String type, bool selected) {
    final list = _recipients;
    final idx = list.indexWhere((e) => e['type'] == type);
    if (selected && idx < 0) list.add({'type': type});
    if (!selected && idx >= 0) list.removeAt(idx);
    if (list.isEmpty) list.add({'type': 'actor'});
    widget.onPatch('recipients', list);
  }

  void _addRecipient(String type, String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    final list = _recipients;
    if (!list.any((e) => e['type'] == type && e['value']?.toString() == v)) {
      list.add({'type': type, 'value': v});
    }
    widget.onPatch('recipients', list);
  }

  void _removeRecipient(int index) {
    final list = _recipients;
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    if (list.isEmpty) list.add({'type': 'actor'});
    widget.onPatch('recipients', list);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final enabled = _asBool(widget.value['enabled'], fallback: true);
    final timing = widget.value['timing']?.toString() ?? 'after_success';
    final priority = widget.value['priority']?.toString() ?? 'normal';
    final delayUnit = _delay['unit']?.toString() ?? 'minutes';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled ? t.dashboardContainer : t.dashboardContainer.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enabled ? t.themeColor.withAlpha(65) : t.dashboardBoarder.withAlpha(120)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Switch(value: enabled, onChanged: (v) => widget.onPatch('enabled', v)),
          Expanded(
            child: Text('Notification',
                style: TextStyle(color: t.textColor, fontWeight: FontWeight.w900, fontSize: 12.5)),
          ),
          IconButton(tooltip: 'Duplicate', onPressed: widget.onDuplicate, icon: const Icon(Icons.copy_rounded, size: 18)),
          IconButton(tooltip: 'Delete', onPressed: widget.onRemove, icon: const Icon(Icons.delete_outline_rounded, size: 18)),
        ]),
        const SizedBox(height: 8),
        CoreDropdown<String>(
          label: 'When to notify',
          value: _timingOptions(widget.nodeType).contains(timing) ? timing : 'after_success',
          options: _timingOptions(widget.nodeType),
          display: _timingLabel,
          prefixIcon: const Icon(Icons.schedule_send_rounded),
          onChanged: (v) => v == null ? null : widget.onPatch('timing', v),
        ),
        const SizedBox(height: 12),
        _Section(
          theme: t,
          title: 'Channels',
          icon: Icons.settings_input_antenna_rounded,
          children: [
            for (final c in _channelOptions)
              FilterChip(
                selected: _channels.contains(c),
                label: Text(_channelLabel(c)),
                avatar: Icon(_channelIcon(c), size: 15),
                onSelected: (selected) => _toggleChannel(c, selected),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          theme: t,
          title: 'Recipients',
          icon: Icons.group_rounded,
          children: [
            for (final r in _recipientTypes)
              FilterChip(
                selected: _recipients.any((e) => e['type'] == r),
                label: Text(_recipientLabel(r)),
                avatar: Icon(_recipientIcon(r), size: 15),
                onSelected: (selected) => _toggleRecipient(r, selected),
              ),
          ],
        ),
        if (_recipients.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < _recipients.length; i++)
              InputChip(
                avatar: Icon(_recipientIcon(_recipients[i]['type']?.toString() ?? ''), size: 15),
                label: Text(_recipientChip(_recipients[i])),
                onDeleted: () => _removeRecipient(i),
              ),
          ]),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: CoreTextField(
              label: 'Add email',
              controller: customEmail,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              onSubmitted: (v) {
                _addRecipient('email', v);
                customEmail.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () {
              _addRecipient('email', customEmail.text);
              customEmail.clear();
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: CoreTextField(
              label: 'Add user ID',
              controller: customUserId,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: const Icon(Icons.person_add_alt_rounded),
              onSubmitted: (v) {
                _addRecipient('user_id', v);
                customUserId.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () {
              _addRecipient('user_id', customUserId.text);
              customUserId.clear();
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ]),
        const SizedBox(height: 12),
        _TemplateField(theme: t, label: 'Title', controller: title, variables: widget.variables, prefixIcon: const Icon(Icons.title_rounded), onChanged: (v) => widget.onPatch('title', v)),
        const SizedBox(height: 12),
        _TemplateField(theme: t, label: 'Message', controller: message, variables: widget.variables, multiline: true, prefixIcon: const Icon(Icons.message_outlined), onChanged: (v) => widget.onPatch('message', v)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: CoreTextField(label: 'Icon', controller: icon, prefixIcon: const Icon(Icons.emoji_symbols_rounded), onChanged: (v) => widget.onPatch('icon', v))),
          const SizedBox(width: 10),
          Expanded(
            child: CoreDropdown<String>(
              label: 'Priority',
              value: _priorities.contains(priority) ? priority : 'normal',
              options: _priorities,
              display: _priorityLabel,
              prefixIcon: const Icon(Icons.priority_high_rounded),
              onChanged: (v) => v == null ? null : widget.onPatch('priority', v),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        CoreTextField(label: 'Image URL / avatar', controller: imageUrl, keyboardType: TextInputType.url, prefixIcon: const Icon(Icons.image_outlined), onChanged: (v) => widget.onPatch('image_url', v)),
        const SizedBox(height: 12),
        CoreTextField(label: 'Deep link / URL', controller: linkUrl, keyboardType: TextInputType.url, prefixIcon: const Icon(Icons.link_rounded), onChanged: (v) => widget.onPatch('link_url', v)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: CoreTextField(
              label: 'Delay amount',
              controller: delayAmount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: const Icon(Icons.timer_outlined),
              onChanged: (v) => _patchDelay('amount', int.tryParse(v.trim()) ?? 0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CoreDropdown<String>(
              label: 'Delay unit',
              value: _delayUnits.contains(delayUnit) ? delayUnit : 'minutes',
              options: _delayUnits,
              display: _unitLabel,
              prefixIcon: const Icon(Icons.timelapse_rounded),
              onChanged: (v) => v == null ? null : _patchDelay('unit', v),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        CoreTextField(
          label: 'Cooldown minutes',
          controller: cooldown,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefixIcon: const Icon(Icons.hourglass_bottom_rounded),
          onChanged: (v) => widget.onPatch('cooldown_minutes', int.tryParse(v.trim()) ?? 0),
        ),
        const SizedBox(height: 12),
        CoreTextField(label: 'Throttle key', controller: throttle, prefixIcon: const Icon(Icons.fingerprint_rounded), onChanged: (v) => widget.onPatch('throttle_key', v)),
        const SizedBox(height: 8),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: _asBool(widget.value['include_context'], fallback: true),
          onChanged: (v) => widget.onPatch('include_context', v),
          title: Text('Include workflow context', style: TextStyle(color: t.textColor, fontSize: 12, fontWeight: FontWeight.w900)),
          subtitle: Text('Attach node output and route metadata.', style: TextStyle(color: t.textColor.withAlpha(145), fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  List<String> _timingOptions(String nodeType) {
    final out = ['before_node', 'after_success', 'after_error', 'always_after'];
    if (['condition', 'switch', 'ai_prompt'].contains(nodeType)) out.add('after_branch');
    if (nodeType == 'delay') out.addAll(['waiting', 'resumed']);
    if (nodeType == 'approval') out.addAll(['approval_required', 'approved', 'rejected', 'expired']);
    return out;
  }
}

class _TemplateField extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final TextEditingController controller;
  final List<AutomationNotificationVariable> variables;
  final ValueChanged<String> onChanged;
  final bool multiline;
  final Widget? prefixIcon;

  const _TemplateField({
    required this.theme,
    required this.label,
    required this.controller,
    required this.variables,
    required this.onChanged,
    this.multiline = false,
    this.prefixIcon,
  });

  void _insert(String token) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final next = text.replaceRange(start, end, token);
    controller.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: start + token.length));
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return CoreTextField(
      label: label,
      controller: controller,
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 8 : 1,
      keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
      textInputAction: multiline ? TextInputAction.newline : TextInputAction.done,
      prefixIcon: prefixIcon,
      suffixIcon: variables.isEmpty
          ? null
          : PopupMenuButton<String>(
              tooltip: 'Insert variable',
              icon: const Icon(Icons.add_link_rounded),
              onSelected: _insert,
              itemBuilder: (_) => [
                for (final v in variables)
                  PopupMenuItem(
                    value: v.token,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(v.icon, size: 18),
                      title: Text(v.label),
                      subtitle: Text(v.token),
                    ),
                  ),
              ],
            ),
      onChanged: onChanged,
    );
  }
}

class _Section extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({required this.theme, required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: theme.themeColor, size: 15),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(color: theme.textColor, fontSize: 11.5, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 7),
      Wrap(spacing: 7, runSpacing: 7, children: children),
    ]);
  }
}

class _Counter extends StatelessWidget {
  final ThemeColors theme;
  final int count;
  const _Counter({required this.theme, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.themeColor.withAlpha(55)),
      ),
      child: Text('$count', style: TextStyle(color: theme.themeColor, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

class _Empty extends StatelessWidget {
  final ThemeColors theme;
  final VoidCallback onAdd;
  const _Empty({required this.theme, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.themeColor.withAlpha(36)),
      ),
      child: Column(children: [
        Icon(Icons.notifications_none_rounded, color: theme.themeColor, size: 26),
        const SizedBox(height: 8),
        Text('No notifications for this block yet.', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 4),
        Text('Add one to notify users, teams, admins, emails or webhooks.', textAlign: TextAlign.center, style: TextStyle(color: theme.textColor.withAlpha(145), fontWeight: FontWeight.w600, fontSize: 11)),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Add notification')),
      ]),
    );
  }
}

const _channelOptions = ['in_app', 'push', 'email', 'sms', 'webhook', 'slack', 'telegram'];
const _recipientTypes = ['actor', 'workflow_owner', 'started_by', 'requested_by', 'company_admins', 'team_members'];
const _priorities = ['low', 'normal', 'high', 'urgent'];
const _delayUnits = ['seconds', 'minutes', 'hours', 'days'];

String _timingLabel(String v) => {
  'before_node': 'Before block starts',
  'after_success': 'After success',
  'after_error': 'After error',
  'always_after': 'Always after finish',
  'after_branch': 'After branch selected',
  'waiting': 'When workflow waits',
  'resumed': 'When workflow resumes',
  'approval_required': 'Approval required',
  'approved': 'Approved',
  'rejected': 'Rejected',
  'expired': 'Expired',
}[v] ?? v;

String _channelLabel(String v) => {
  'in_app': 'In-app',
  'push': 'Push',
  'email': 'Email',
  'sms': 'SMS',
  'webhook': 'Webhook',
  'slack': 'Slack',
  'telegram': 'Telegram',
}[v] ?? v;

IconData _channelIcon(String v) => {
  'in_app': Icons.notifications_rounded,
  'push': Icons.phone_iphone_rounded,
  'email': Icons.mail_outline_rounded,
  'sms': Icons.sms_outlined,
  'webhook': Icons.webhook_rounded,
  'slack': Icons.tag_rounded,
  'telegram': Icons.send_rounded,
}[v] ?? Icons.notifications_none_rounded;

String _recipientLabel(String v) => {
  'actor': 'Actor',
  'workflow_owner': 'Owner',
  'started_by': 'Started by',
  'requested_by': 'Requested by',
  'company_admins': 'Company admins',
  'team_members': 'Team',
  'email': 'Email',
  'user_id': 'User ID',
}[v] ?? v;

IconData _recipientIcon(String v) => {
  'actor': Icons.person_rounded,
  'workflow_owner': Icons.admin_panel_settings_rounded,
  'started_by': Icons.play_circle_outline_rounded,
  'requested_by': Icons.assignment_ind_rounded,
  'company_admins': Icons.apartment_rounded,
  'team_members': Icons.groups_rounded,
  'email': Icons.alternate_email_rounded,
  'user_id': Icons.badge_rounded,
}[v] ?? Icons.person_outline_rounded;

String _recipientChip(Map<String, dynamic> e) {
  final type = e['type']?.toString() ?? '';
  final value = e['value']?.toString() ?? '';
  return value.trim().isEmpty ? _recipientLabel(type) : '${_recipientLabel(type)}: $value';
}

String _priorityLabel(String v) => {'low': 'Low', 'normal': 'Normal', 'high': 'High', 'urgent': 'Urgent'}[v] ?? v;
String _unitLabel(String v) => {'seconds': 'Seconds', 'minutes': 'Minutes', 'hours': 'Hours', 'days': 'Days'}[v] ?? v;

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return Map<String, dynamic>.from(v);
  if (v is Map) return Map<String, dynamic>.from(v);
  return {};
}

List<Map<String, dynamic>> _asMapList(dynamic v) {
  if (v is! List) return [];
  return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

List<String> _asStringList(dynamic v) {
  if (v is List) return v.map((e) => e?.toString().trim() ?? '').where((e) => e.isNotEmpty).toList();
  final text = v?.toString().trim() ?? '';
  if (text.isEmpty) return [];
  return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

bool _asBool(dynamic v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final raw = v?.toString().trim().toLowerCase() ?? '';
  if (['true', '1', 'yes', 'tak'].contains(raw)) return true;
  if (['false', '0', 'no', 'nie'].contains(raw)) return false;
  return fallback;
}
