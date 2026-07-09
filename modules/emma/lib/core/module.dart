import 'package:core/kernel/kernel.dart';

import 'package:emma/runner.dart';
import 'package:emma/settings/emma_settings_body.dart';
import 'package:emma/settings/settings_emma_style_pc.dart';
import 'package:emma/settings/settings_emma_style_mobile.dart';
import 'package:emma/settings/settings_emma_memory_mobile.dart';

/// Registration surface for the emma (AI assistant) module. Exposes the AI
/// layer overlay via the widget-slot registry so the shell / navigation layer
/// can open it without importing emma directly.
class EmmaModule extends AppModule {
  @override
  String get id => 'emma';

  @override
  Map<String, SlotBuilder> widgetSlots() => {
        'layer.ai': (context, args) => const ChatAiPage(),
        'emma.settingsBody': (context, args) => const EmmaSettingsBody(),
      };

  @override
  List<SettingsContribution> settingsSections() => [
        SettingsContribution(
          id: 'emma_style',
          titleKey: 'Styl pisania Emmy',
          iconKey: 'ai',
          order: 90,
          pcPage: (context, args) => const EmmaStyleSettingsPc(),
          mobilePage: (context, args) => const EmmaStyleSettingsMobile(),
        ),
        SettingsContribution(
          id: 'emma_memory',
          titleKey: 'Co Emma o mnie pamięta',
          iconKey: 'ai',
          order: 91,
          pcPage: (context, args) => const EmmaMemorySettingsMobile(),
          mobilePage: (context, args) => const EmmaMemorySettingsMobile(),
        ),
      ];
}
