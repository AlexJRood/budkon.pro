// lib/screens/association_notifications/utils/campaign_ui_utils.dart
// Comments are in English as requested.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:association/models/notifications_model.dart';

String campaignSubtitleFor(AssociationNotificationCampaign c) {
  final df = DateFormat('yyyy-MM-dd HH:mm');
  String left = 'Utworzono: ${df.format(c.createdAt)}';
  if (c.scheduledAt != null) {
    left += '  •  Plan: ${df.format(c.scheduledAt!)}';
  }
  final right = 'Wysłano: ${c.sentSuccess}/${c.totalRecipients}';
  return '$left\n$right';
}

Widget campaignStatusChip({required String status}) {
  Color col;
  switch (status) {
    case AssocCampaignStatus.sending:
      col = Colors.blue;
      break;
    case AssocCampaignStatus.scheduled:
      col = Colors.orange;
      break;
    case AssocCampaignStatus.sent:
      col = Colors.green;
      break;
    case AssocCampaignStatus.cancelled:
      col = Colors.grey;
      break;
    case AssocCampaignStatus.failed:
      col = Colors.red;
      break;
    default:
      col = Colors.indigo;
  }
  return Chip(label: Text(status), backgroundColor: col.withAlpha(38));
}
