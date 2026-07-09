import 'package:core/kernel/kernel.dart';

import 'package:notification/notification_screen.dart';
import 'package:notification/settings/settings_notification_pc.dart';
import 'package:notification/settings/settings_notification_mobile.dart';

/// Registration surface for the notification module. Exposes the notifications
/// layer overlay via the widget-slot registry so the shell / navigation layer
/// can open it without importing notification directly.
class NotificationModule extends AppModule {
  @override
  String get id => 'notification';

  @override
  Map<String, SlotBuilder> widgetSlots() => {
        'layer.notifications': (context, args) => const NotificationScreen(),
      };

  @override
  List<SettingsContribution> settingsSections() => [
        SettingsContribution(
          id: 'notifications',
          titleKey: 'Notifications',
          iconKey: 'notification',
          order: 20,
          pcPage: (context, args) => const NotificationScreenPc(),
          mobilePage: (context, args) => const SettingsNotificationMobile(),
        ),
      ];
}
