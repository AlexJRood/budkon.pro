// lib/screens/association_notifications/widgets/preview_recipients.dart
// Comments are in English as requested.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:association/models/notifications_model.dart';
import 'package:core/theme/apptheme.dart';

class PreviewRecipientsCard extends StatelessWidget {
  const PreviewRecipientsCard({
    super.key,
    required this.items,
    required this.theme,
  });

  final List<RecipientPreview> items;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Podgląd odbiorców (pierwsze 10)',
              style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text('Brak podglądu.', style: TextStyle(color: theme.textColor)))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final r = items[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            r.memberName.isEmpty ? r.memberId : r.memberName,
                            style: TextStyle(color: theme.textColor),
                          ),
                          subtitle: Text(
                            r.status +
                                (r.error != null && r.error!.isNotEmpty ? '  •  ${r.error}' : ''),
                            style: TextStyle(color: theme.textColor.withAlpha(140)),
                          ),
                          trailing: r.sentAt != null
                              ? Text(
                                  DateFormat('MM-dd HH:mm').format(r.sentAt!.toLocal()),
                                  style: TextStyle(color: theme.textColor),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
