// lib/screens/association_notifications/create/status_selector.dart
// Comments are in English as requested.

import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';

class StatusSelector extends StatelessWidget {
  const StatusSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.theme,
  });

  final ThemeColors theme;
  final Set<String> selected;
  final void Function(Set<String>) onChanged;

  @override
  Widget build(BuildContext context) {
    final options = const ['active', 'pending', 'suspended', 'former'];

    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statusy członków', style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((s) {
                final isSel = selected.contains(s);
                return FilterChip(
                  selectedColor: theme.dashboardBoarder,
                  backgroundColor: theme.dashboardContainer,
                  checkmarkColor: theme.textColor,
                  label: Text(s, style: TextStyle(color: theme.textColor)),
                  selected: isSel,
                  onSelected: (v) {
                    final next = {...selected};
                    if (v) {
                      next.add(s);
                    } else {
                      next.remove(s);
                    }
                    onChanged(next);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
