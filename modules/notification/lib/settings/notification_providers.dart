import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettings {
  Map<String, bool> settings;

  NotificationSettings({
    Map<String, bool>? initialSettings,
  }) : settings = initialSettings ??
            {
              'desktopNotification': false,
              'mobileNotification': false,
              'emailNotification': false,
              'allowSound': false,
              'flashTaskbar': false,
              'messages': false,
              'pinnedMessages': false,
              'clientRequest': false,
              'newOpertunities': false,
              'taskManager': false,
              'meetings': false,
              'activity': false,
              'clientActivity': false,
            };

  void toggleSetting(String key) {
    if (settings.containsKey(key)) {
      settings[key] = !settings[key]!;
    }
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(NotificationSettings());

  // Toggle a specific setting based on its key
  void toggleSetting(String key) {
    state.toggleSetting(key);
    state = NotificationSettings(
        initialSettings:
            Map.from(state.settings)); // Recreate state to trigger change
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  (ref) => NotificationSettingsNotifier(),
);


