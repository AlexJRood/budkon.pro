import 'package:flutter/widgets.dart';
import 'package:core/kernel/kernel.dart';

import 'package:mail/settings/settings_mail_pc.dart';
import 'package:mail/settings/setting_mail_mobile.dart';

import 'dock.dart';
import 'routing.dart';
import 'translate.dart';

/// Registration surface for the mail module. The host app sees mail only
/// through [AppModule] (via the [ModuleRegistry]); it never imports mail's
/// pages directly.
class MailModule extends AppModule {
  @override
  String get id => 'mail';

  @override
  List<DockContribution> dockItems() => mailDockItems();

  @override
  Map<String, Map<String, String>> translations() => mailTranslations();

  @override
  Map<String, SlotBuilder> widgetSlots() => {
        // Embedded mail-settings screen used by the onboarding "email" step.
        // Slot-resolved so core/onboarding doesn't import mail.
        'settings.mail.onboarding': (context, args) => EmailScreenPc(
              removeHorizontalPadding:
                  (args['removeHorizontalPadding'] as bool?) ?? false,
            ),
      };

  @override
  List<SettingsContribution> settingsSections() => [
        SettingsContribution(
          id: 'mail',
          titleKey: 'Email',
          iconKey: 'mail',
          order: 50,
          pcPage: (context, args) => const EmailScreenPc(),
          mobilePage: (context, args) => const SettingMailMobile(),
        ),
      ];

  @override
  Map<Pattern, BeamRouteBuilder> routeMap() => mailRoutes;
}
