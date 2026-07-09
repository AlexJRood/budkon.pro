// lib/screens/association_notifications/widgets/action_buttons.dart
// Comments are in English as requested.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:association/models/notifications_model.dart';
import 'package:association/providers/notifications.dart';
import 'package:core/theme/apptheme.dart';

class AssociationCampaignActionButtons extends ConsumerWidget {
  const AssociationCampaignActionButtons({
    super.key,
    required this.baseUrl,
    required this.theme,
    required this.campaign,
    required this.onDone,
  });

  final String baseUrl;
  final AssociationNotificationCampaign campaign;
  final Future<void> Function() onDone;
  final ThemeColors theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(assocNotifApiProvider(baseUrl));
    final busy = ValueNotifier(false);

    Future<void> doAction(Future<void> Function() f) async {
      if (busy.value) return;
      busy.value = true;
      try {
        await f();
        await onDone();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Gotowe.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Błąd: $e')));
        }
      } finally {
        busy.value = false;
      }
    }

    return ValueListenableBuilder(
      valueListenable: busy,
      builder: (_, bool isBusy, __) {
        return Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: isBusy ? null : () => doAction(() => api.sendNow(campaign.id)),
              icon: Icon(Icons.send, color: theme.textColor),
              label: Text('Wyślij teraz', style: TextStyle(color: theme.textColor)),
            ),
            OutlinedButton.icon(
              onPressed: isBusy ? null : () => doAction(() => api.cancelCampaign(campaign.id)),
              icon: Icon(Icons.cancel, color: theme.textColor),
              label: Text('Anuluj', style: TextStyle(color: theme.textColor)),
            ),
          ],
        );
      },
    );
  }
}
