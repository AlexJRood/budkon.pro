// lib/screens/association_notifications/widgets/json_card.dart
// Comments are in English as requested.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';

class JsonCard extends StatelessWidget {
  const JsonCard({
    super.key,
    required this.title,
    required this.theme,
    required this.value,
  });

  final String title;
  final Object? value;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    final encoded = const JsonEncoder.withIndent('  ').convert(value);

    return Card(
      elevation: 0,
      color: theme.dashboardContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dashboardBoarder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  encoded,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
