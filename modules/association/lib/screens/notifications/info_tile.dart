// lib/screens/association_notifications/widgets/info_tile.dart
// Comments are in English as requested.

import 'package:flutter/material.dart';
import 'package:core/theme/apptheme.dart';

class InfoTile extends StatelessWidget {
  const InfoTile(this.label, this.theme, this.value, {super.key});

  final String label;
  final String value;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: theme.textColor)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor),
          ),
        ],
      ),
    );
  }
}
