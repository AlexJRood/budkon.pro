import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:core/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/common/shared_widgets/gradient_dropdown.dart';
import 'package:core/ui/buttons/action_buttons.dart';
import 'package:core/ui/forms/form_fields.dart';

import 'package:core/theme/apptheme.dart';

import 'package:notification/settings/notification_providers.dart';

class NotificationScreenPc extends ConsumerStatefulWidget {
  const NotificationScreenPc({super.key});

  @override
  ConsumerState<NotificationScreenPc> createState() =>
      _NotificationScreenPcState();
}

String? selectedItem;

class _NotificationScreenPcState extends ConsumerState<NotificationScreenPc> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final proTheme = ref.watch(isDefaultDarkSystemProvider);
    final colorscheme = ref.watch(colorSchemeProvider);
    final isToggled = ref.watch(toggleProvider);
    final setting = ref.read(settingProvider);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isToggled == true) ...[
              const SizedBox(
                height: 1,
              ),
            ],
            HeadingText(text: 'global_settings'.tr),
            const SizedBox(height: 15),
            NotificationToggleTilePc(
              togglevalue: setting?.notifications.desktopNotifications ?? false,
              subtitle: 'stay_updated_with_real_time_notifications_on_your_screen'.tr,
              onChanged: (togglevalue) async {
                await ref
                    .read(settingProvider.notifier)
                    .editSinglePropertyOfSetting(
                  key: 'notifications',
                  value: {
                    ...setting!.notifications.toJson(),
                    'desktop_notifications': togglevalue,
                  },
                );

                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('desktopNotification');
              },
              title: 'desktop_notifications'.tr
            ),
            const SizedBox(height: 4),
            Divider(color: theme.themeTextColor.withAlpha((255 * 0.5).toInt())),
            const SizedBox(height: 12),
            NotificationToggleTilePc(
              togglevalue: setting?.notifications.mobileNotifications ?? false,
              subtitle: 'stay_updated_with_real_time_notifications_on_your_screen'.tr,
              onChanged: (togglevalue) async {
                await ref
                    .read(settingProvider.notifier)
                    .editSinglePropertyOfSetting(
                  key: 'notifications',
                  value: {
                    ...setting!.notifications.toJson(),
                    'mobile_notifications': togglevalue,
                  },
                );
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('mobileNotification');
              },
              title: 'mobile_notifications'.tr
            ),
            const SizedBox(height: 4),
            Divider(color: theme.themeTextColor.withAlpha((255 * 0.5).toInt())),
            const SizedBox(height: 12),
            NotificationToggleTilePc(
              togglevalue: setting?.notifications.emailNotifications ?? false,
              subtitle: 'stay_updated_with_real_time_notifications_on_your_screen'.tr,
              onChanged: (togglevalue) async {
                await ref
                    .read(settingProvider.notifier)
                    .editSinglePropertyOfSetting(
                  key: 'notifications',
                  value: {
                    ...setting!.notifications.toJson(),
                    'email_notifications': togglevalue,
                  },
                );
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('emailNotification');
              },
              title: 'email_notifications'.tr
            ),
            const SizedBox(height: 4),
            Divider(color: theme.themeTextColor.withAlpha((255 * 0.5).toInt())),
            const SizedBox(height: 12),
            NotificationToggleTilePc(
              togglevalue: setting?.notifications.allowSound ?? false,
              title: 'enable_sound'.tr,
              subtitle: 'enable_sound_notifications_for_a_more_interactive_experience'.tr,
              onChanged: (value) async {
                await ref
                    .read(settingProvider.notifier)
                    .editSinglePropertyOfSetting(
                  key: 'notifications',
                  value: {
                    ...setting!.notifications.toJson(),
                    'allow_sound': value,
                  },
                );
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('allowSound');
              },
            ),
            const SizedBox(height: 4),
            Divider(color: theme.themeTextColor.withAlpha((255 * 0.5).toInt())),
            const SizedBox(height: 12),
            NotificationToggleTilePc(
              togglevalue: setting?.notifications.flashTaskbar ?? false,
              title: 'flash_taskbar'.tr,
              subtitle: 'notify_you_about_urgent_updates_or_alerts_using_a_flashing_taskbar'.tr,
              onChanged: (value) async {
                await ref
                    .read(settingProvider.notifier)
                    .editSinglePropertyOfSetting(
                  key: 'notifications',
                  value: {
                    ...setting!.notifications.toJson(),
                    'flash_taskbar': value,
                  },
                );
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('flashTaskbar');
              },
            ),
            const SizedBox(
              height: 25,
            ),
            HeadingText(text: 'sounds'.tr),
            const SizedBox(
              height: 15,
            ),
            NotificationToggleTilePc(
              title: 'messages'.tr,
              subtitle: 'keep_important_messages_easily_accessible_at_the_top_of_the_chat'.tr,
              onChanged: (value) async {
                await ref
                    .read(settingProvider.notifier)
                    .editSinglePropertyOfSetting(
                  key: 'notifications',
                  value: {
                    ...setting!.notifications.toJson(),
                    'messages': value,
                  },
                );
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('messages');
              },
              togglevalue: setting?.notifications.messages ?? false,
            ),
            const SizedBox(height: 4),
            Divider(color: theme.themeTextColor.withAlpha((255 * 0.5).toInt())),
            const SizedBox(height: 12),
            NotificationToggleTilePc(
              title: 'pinned_messages'.tr,
              subtitle: 'keep_important_messages_easily_accessible_at_the_top_of_the_chat'.tr,
              onChanged: (value) async {
                await ref
                    .read(settingProvider.notifier)
                    .editSinglePropertyOfSetting(
                  key: 'notifications',
                  value: {
                    ...setting!.notifications.toJson(),
                    'pinned_messages': value,
                  },
                );
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('pinnedMessages');
              },
              togglevalue: setting?.notifications.pinnedMessages ?? false,
            ),
            const SizedBox(
              height: 25,
            ),
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              height: 810,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient:
                      CustomBackgroundGradients.getSideMenuBackgroundcustom(
                          context, ref),
                  border: Border.all(
                      color: proTheme
                          ? theme.bordercolor
                          : colorscheme == FlexScheme.blackWhite
                              ? Theme.of(context).colorScheme.onSecondary
                              : Theme.of(context).colorScheme.secondary,
                      width: 2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  HeadingText(
                    text: 'do_not_disturb_hours'.tr,
                    color: proTheme
                        ? theme.bordercolor
                        : colorscheme == FlexScheme.blackWhite
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                 SubtitleText(text: 'customize_quiet_hours_to_focus_without_distractions'.tr),
                  const SizedBox(
                    height: 15,
                  ),
                  HeadingText(text: 'select_time'.tr, fontsize: 12),
                  const SizedBox(
                    height: 4,
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: GradientDropdown(
                              isPc: true,
                              value: "",
                              gradientcontroller: false,
                              hintText: 'select_a_time'.tr,
                              items: [
                                '50_minutes'.tr,
                                '30_minutes'.tr,
                                '10_minutes'.tr,
                                '5_minutes'.tr
                              ],
                              selectedItem: selectedItem,
                              onChanged: (value) async {
                                await ref
                                    .read(settingProvider.notifier)
                                    .editSinglePropertyOfSetting(
                                  key: 'notifications',
                                  value: {
                                    ...setting!.notifications.toJson(),
                                    'do_not_disturb_time': value,
                                  },
                                );
                                setState(() {
                                  selectedItem = value;
                                });
                              })),
                    ],
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  HeadingText(
                    text: 'custom_notification_filters'.tr,
                    color: proTheme
                        ? theme.bordercolor
                        : colorscheme == FlexScheme.blackWhite
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                 SubtitleText(text: 'customize_which_events_or_messages_trigger_notifications_to_help_you_stay_informed'.tr),
                  const SizedBox(
                    height: 25,
                  ),
                  NotificationToggleTilePc(
                    fontsize: 17,
                    title: 'new_client_requests'.tr,
                    subtitle: 'receive_notifications_when_a_client_submits_a_new_inquiry'.tr,
                    onChanged: (value) async {
                      await ref
                          .read(settingProvider.notifier)
                          .editSinglePropertyOfSetting(
                        key: 'notifications',
                        value: {
                          ...setting!.notifications.toJson(),
                          'new_client_requests': value,
                        },
                      );
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('clientRequest');
                    },
                    togglevalue:
                        setting?.notifications.newClientRequests ?? false,
                  ),
                  const SizedBox(height: 4),
                  Divider(color: theme.themeTextColor.withAlpha((255 * 0.5).toInt())),
                  const SizedBox(height: 12),
                  NotificationToggleTilePc(
                    fontsize: 17,
                    title: 'new_opportunities'.tr,
                    subtitle: 'notify_when_a_new_sales_opportunity_is_identified_for_a_client'.tr,
                    onChanged: (value) async {
                      await ref
                          .read(settingProvider.notifier)
                          .editSinglePropertyOfSetting(
                        key: 'notifications',
                        value: {
                          ...setting!.notifications.toJson(),
                          'new_opportunities': value,
                        },
                      );
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('newOpertunities');
                    },
                    togglevalue:
                        setting?.notifications.newOpportunities ?? false,
                  ),
                  const SizedBox(height: 4),
                  Divider(color: theme.themeTextColor.withAlpha((255 * 0.5).toInt())),
                  const SizedBox(height: 12),
                  NotificationToggleTilePc(
                    fontsize: 17,
                    title: 'task_reminders'.tr,
                    subtitle: 'notifications_about_upcoming_tasks_or_deadlines'.tr,
                    onChanged: (value) async {
                      await ref
                          .read(settingProvider.notifier)
                          .editSinglePropertyOfSetting(
                        key: 'notifications',
                        value: {
                          ...setting!.notifications.toJson(),
                          'task_reminders': value,
                        },
                      );
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('taskManager');
                    },
                    togglevalue: setting?.notifications.taskReminders ?? false,
                  ),
                  const SizedBox(height: 4),
                  Divider(color: theme.themeTextColor.withAlpha((255 * 0.5).toInt())),
                  const SizedBox(height: 12),
                  NotificationToggleTilePc(
                    fontsize: 17,
                    title: 'scheduled_meetings'.tr,
                    subtitle: 'receive_reminders_about_upcoming_meetings_or_client_conversations'.tr,
                    onChanged: (value) async {
                      await ref
                          .read(settingProvider.notifier)
                          .editSinglePropertyOfSetting(
                        key: 'notifications',
                        value: {
                          ...setting!.notifications.toJson(),
                          'scheduled_meetings': value,
                        },
                      );
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('meetings');
                    },
                    togglevalue:
                        setting?.notifications.scheduledMeetings ?? false,
                  ),
                  const SizedBox(height: 4),
                  Divider(color: theme.themeTextColor.withAlpha((255 * 0.5).toInt())),
                  const SizedBox(height: 12),
                  NotificationToggleTilePc(
                    fontsize: 17,
                    title: 'client_activity'.tr,
                    subtitle: 'notifications_when_a_client_takes_action_such_as_clicking_a_proposal_making_a_payment_or_submitting_a_support_request'.tr,
                    onChanged: (value) async {
                      await ref
                          .read(settingProvider.notifier)
                          .editSinglePropertyOfSetting(
                        key: 'notifications',
                        value: {
                          ...setting!.notifications.toJson(),
                          'client_activity': value,
                        },
                      );
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('activity');
                    },
                    togglevalue: setting?.notifications.clientActivity ?? false,
                  ),
                  const SizedBox(height: 4),
                  Divider(color: theme.themeTextColor.withAlpha((255 * 0.5).toInt())),
                  const SizedBox(height: 12),
                  NotificationToggleTilePc(
                    fontsize: 17,
                    title: 'clients_with_support_requests'.tr,
                    subtitle: 'receive_notifications_when_a_client_submits_a_support_request_or_issue'.tr,
                    onChanged: (value) async {
                      await ref
                          .read(settingProvider.notifier)
                          .editSinglePropertyOfSetting(
                        key: 'notifications',
                        value: {
                          ...setting!.notifications.toJson(),
                          'client_activity': value,
                        },
                      );
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .toggleSetting('clientActivity');
                    },
                    togglevalue: setting?.notifications.clientActivity ?? false,
                  ),
                  const SizedBox(height: 4),
                  Divider(color: theme.themeTextColor.withAlpha((255 * 0.5).toInt())),
                  const SizedBox(height: 12),
                  SizedBox(height: 30),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
