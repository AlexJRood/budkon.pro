import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/text_field.dart';

import '../../models/automation_common.dart';

class AutomationScopeSelector extends ConsumerWidget {
  final AutomationScopeType value;
  final ValueChanged<AutomationScopeType> onChanged;
  final int? companyId;
  final int? teamId;
  final int? userId;

  const AutomationScopeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.companyId,
    this.teamId,
    this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final options = <AutomationScopeType>[
      AutomationScopeType.user,
      if (companyId != null || value == AutomationScopeType.company)
        AutomationScopeType.company,
      if (teamId != null || value == AutomationScopeType.team)
        AutomationScopeType.team,
      if (value == AutomationScopeType.system)
        AutomationScopeType.system,
    ];

    final selectedValue = options.contains(value)
        ? value
        : AutomationScopeType.user;

    return SizedBox(
      width: 230,
      child: CoreDropdown<AutomationScopeType>(
        label: 'Scope',
        value: selectedValue,
        options: options,
        hintText: 'Choose scope',
        fillColor: theme.adPopBackground,
        prefixIcon: const Icon(Icons.visibility_rounded),
        onChanged: (next) {
          if (next == null) return;
          onChanged(next);
        },
        display: _displayScope,
      ),
    );
  }

  String _displayScope(AutomationScopeType item) {
    switch (item) {
      case AutomationScopeType.user:
        return 'User';
      case AutomationScopeType.company:
        return 'Company';
      case AutomationScopeType.team:
        return 'Team';
      case AutomationScopeType.system:
        return 'System';
    }
  }
}
