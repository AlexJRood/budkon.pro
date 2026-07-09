// lib/screens/association_notifications/create/schedule_picker.dart
// Comments are in English as requested.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:core/theme/apptheme.dart';

class SchedulePicker extends StatelessWidget {
  const SchedulePicker({
    super.key,
    required this.scheduledAt,
    required this.onPick,
    required this.theme,
  });

  final ThemeColors theme;
  final DateTime? scheduledAt;
  final void Function(DateTime?) onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Text('Plan wysyłki:', style: TextStyle(color: theme.textColor)),
            const SizedBox(width: 12),
            Text(
              scheduledAt == null
                  ? 'natychmiast'
                  : DateFormat('yyyy-MM-dd HH:mm').format(scheduledAt!.toLocal()),
              style: TextStyle(color: theme.textColor)
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  firstDate: now,
                  lastDate: DateTime(now.year + 5),
                  initialDate: scheduledAt ?? now,
                );
                if (d == null) return;

                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(scheduledAt ?? now),
                );
                if (t == null) return;

                final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                onPick(dt.toUtc()); // send UTC to backend
              },
              icon:  Icon(Icons.calendar_today, color: theme.textColor),
              label: Text('Ustaw', style: TextStyle(color: theme.textColor)),
            ),
            const SizedBox(width: 8),
            if (scheduledAt != null)
              TextButton(
                onPressed: () => onPick(null),
                child: Text('Wyczyść', style: TextStyle(color: theme.textColor)),
              ),
          ],
        ),
      ),
    );
  }
}
