import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:core/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/theme/backgroundgradient.dart';
import 'package:core/common/shared_widgets/gradient_dropdown.dart';
import 'package:core/ui/buttons/app_buttons.dart';
import 'package:notification/settings/notification_providers.dart';
import 'package:core/ui/forms/form_fields.dart';
import 'package:core/theme/apptheme.dart';
import 'package:get/get_utils/get_utils.dart';

class SettingsNotificationMobile extends ConsumerStatefulWidget {
  const SettingsNotificationMobile({super.key});

  @override
  ConsumerState<SettingsNotificationMobile> createState() =>
      _SettingsNotificationMobileState();
}

String? selectedItem;

class _SettingsNotificationMobileState
    extends ConsumerState<SettingsNotificationMobile> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final proTheme = ref.watch(isDefaultDarkSystemProvider);
    final colorscheme = ref.watch(colorSchemeProvider);
    ref.watch(toggleProvider);
    final colorScheme = ref.watch(colorSchemeProvider);
   
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              CustomBackgroundGradients.getMainMenuBackground(context, ref),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            MobileSettingsAppbar(
              title: "notifications".tr,
              onPressed: () => ref.read(navigationService).beamPop(),),
            Expanded(
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        'global_settings'.tr,
                        style: TextStyle(
                            color: theme.mobileTextcolor, fontSize: 20),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      NotificationToggleTileMobile(
                        togglevalue: notificationSettings
                            .settings['desktopNotification']!,
                        subtitle:
                            'stay_updated_with_real_time_notifications_on_your_screen'.tr,
                        onChanged: (togglevalue) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .toggleSetting('desktopNotification');
                        },
                        title: 'desktop_notifications'.tr
                      ),
                      const SizedBox(height: 4),
                      Divider(color: theme.themeTextColor),
                      const SizedBox(height: 12),
                      NotificationToggleTileMobile(
                        togglevalue: notificationSettings
                            .settings['mobileNotification']!,
                        subtitle:
                            'stay_updated_with_real_time_notifications_on_your_screen'.tr,
                        onChanged: (togglevalue) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .toggleSetting('mobileNotification');
                        },
                        title: 'mobile_notifications'.tr
                      ),
                      const SizedBox(height: 4),
                      Divider(color: theme.themeTextColor),
                      const SizedBox(height: 12),
                      NotificationToggleTileMobile(
                        togglevalue:
                            notificationSettings.settings['emailNotification']!,
                        subtitle:
                            'stay_updated_with_real_time_notifications_on_your_screen'.tr,
                        onChanged: (togglevalue) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .toggleSetting('emailNotification');
                        },
                        title: 'email_notifications'.tr,
                      ),
                      const SizedBox(height: 4),
                      Divider(color: theme.themeTextColor),
                      const SizedBox(height: 12),
                      NotificationToggleTileMobile(
                        togglevalue:
                            notificationSettings.settings['allowSound']!,
                        title: 'enable_sound'.tr,
                        subtitle:
                            'enable_sound_notifications_for_a_more_interactive_experience'.tr,
                        onChanged: (value) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .toggleSetting('allowSound');
                        },
                      ),
                      const SizedBox(height: 4),
                      Divider(color: theme.themeTextColor),
                      const SizedBox(height: 12),
                      NotificationToggleTileMobile(
                        togglevalue:
                            notificationSettings.settings['flashTaskbar']!,
                        title: 'flash_taskbar'.tr,
                        subtitle:
                            'notify_you_about_urgent_updates_or_alerts_using_a_flashing_taskbar'.tr,
                        onChanged: (value) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .toggleSetting('flashTaskbar');
                        },
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      Text(
                        'sounds'.tr,
                        style: TextStyle(
                            color: theme.mobileTextcolor, fontSize: 20),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      NotificationToggleTileMobile(
                        title: 'messages'.tr,
                        subtitle:
                            'keep_important_messages_easily_accessible_at_the_top_of_the_chat'.tr,
                        onChanged: (value) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .toggleSetting('messages');
                        },
                        togglevalue: notificationSettings.settings['messages']!,
                      ),
                      const SizedBox(height: 4),
                      Divider(color: theme.themeTextColor),
                      const SizedBox(height: 12),
                      NotificationToggleTileMobile(
                        title: 'pinned_messages'.tr,
                        subtitle:
                            'keep_important_messages_easily_accessible_at_the_top_of_the_chat'.tr,
                        onChanged: (value) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .toggleSetting('pinnedMessages');
                        },
                        togglevalue:
                            notificationSettings.settings['pinnedMessages']!,
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: CustomBackgroundGradients
                                .getSideMenuBackgroundcustom(context, ref),
                            border: Border.all(
                                color: proTheme
                                    ? theme.bordercolor
                                    : colorscheme == FlexScheme.blackWhite
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSecondary
                                        : Theme.of(context)
                                            .colorScheme
                                            .secondary,
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
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSecondary
                                      : Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Text(
                              'customize_quiet_hours_to_focus_without_distractions'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .iconTheme
                                    .color!
                                    .withAlpha((255 * 0.7).toInt()),
                              ),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            HeadingText(
                              text: 'select_time'.tr,
                              fontsize: 12,
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: GradientDropdown(
                                        isPc: false,
                                        value: "",
                                        gradientcontroller: false,
                                        hintText: 'select_a_time'.tr,
                                        items: [
                                          '50_minutes'.tr,
                                          '30_minutes'.tr,
                                          '10_minutes'.tr,
                                          '5_minutes'.tr,
                                        ],
                                        selectedItem: selectedItem,
                                        onChanged: (value) {
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
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSecondary
                                      : Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            Text(
                              'customize_which_events_or_messages_trigger_notifications_to_help_you_stay_informed'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .iconTheme
                                    .color!
                                    .withAlpha((255 * 0.7).toInt()),
                              ),
                            ),
                            const SizedBox(
                              height: 25,
                            ),
                            NotificationToggleTileMobile(
                              onGradient: true,
                              title: 'new_client_requests'.tr,
                              subtitle:
                                  'receive_notifications_when_a_client_submits_a_new_inquiry'.tr,
                              onChanged: (value) {
                                ref
                                    .read(notificationSettingsProvider.notifier)
                                    .toggleSetting('clientRequest');
                              },
                              togglevalue: notificationSettings
                                  .settings['clientRequest']!,
                            ),
                            const SizedBox(height: 4),
                            Divider(color: theme.themeTextColor),
                            const SizedBox(height: 12),
                            NotificationToggleTileMobile(
                              onGradient: true,
                              title: 'new_opportunities'.tr,
                              subtitle:
                                 'notify_when_a_new_sales_opportunity_is_identified_for_a_client'.tr,
                              onChanged: (value) {
                                ref
                                    .read(notificationSettingsProvider.notifier)
                                    .toggleSetting('newOpertunities');
                              },
                              togglevalue: notificationSettings
                                  .settings['newOpertunities']!,
                            ),
                            const SizedBox(height: 4),
                            Divider(color: theme.themeTextColor),
                            const SizedBox(height: 12),
                            NotificationToggleTileMobile(
                              onGradient: true,
                              title: 'task_reminders'.tr,
                              subtitle:
                                  'notifications_about_upcoming_tasks_or_deadlines'.tr,
                              onChanged: (value) {
                                ref
                                    .read(notificationSettingsProvider.notifier)
                                    .toggleSetting('taskManager');
                              },
                              togglevalue:
                                  notificationSettings.settings['taskManager']!,
                            ),
                            const SizedBox(height: 4),
                            Divider(color: theme.themeTextColor),
                            const SizedBox(height: 12),
                            NotificationToggleTileMobile(
                              onGradient: true,
                              title: 'scheduled_meetings'.tr,
                              subtitle:
                                  'receive_reminders_about_upcoming_meetings_or_client_conversations'.tr,
                              onChanged: (value) {
                                ref
                                    .read(notificationSettingsProvider.notifier)
                                    .toggleSetting('meetings');
                              },
                              togglevalue:
                                  notificationSettings.settings['meetings']!,
                            ),
                            const SizedBox(height: 4),
                            Divider(color: theme.themeTextColor),
                            const SizedBox(height: 12),
                            NotificationToggleTileMobile(
                              onGradient: true,
                              title: 'client_activity'.tr,
                              subtitle:
                                  'notifications_when_a_client_takes_action_such_as_clicking_a_proposal_making_a_payment_or_submitting_a_support_request'.tr,
                              onChanged: (value) {
                                ref
                                    .read(notificationSettingsProvider.notifier)
                                    .toggleSetting('activity');
                              },
                              togglevalue:
                                  notificationSettings.settings['activity']!,
                            ),
                            const SizedBox(height: 4),
                            Divider(color: theme.themeTextColor),
                            const SizedBox(height: 12),
                            NotificationToggleTileMobile(
                              onGradient: true,
                              title: 'clients_with_support_requests'.tr,
                              subtitle:
                                  'receive_notifications_when_a_client_submits_a_support_request_or_issue'.tr,
                              onChanged: (value) {
                                ref
                                    .read(notificationSettingsProvider.notifier)
                                    .toggleSetting('clientActivity');
                              },
                              togglevalue: notificationSettings
                                  .settings['clientActivity']!,
                            ),
                            const SizedBox(height: 4),
                            Divider(color: theme.themeTextColor),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: SettingsButton(
                                      icon: Icons.auto_awesome,
                                      hasIcon: true,
                                      isPc: false,
                                      isborder:
                                          colorScheme == FlexScheme.blackWhite,
                                      buttonheight: 48,
                                      onTap: () {},
                                      text: "upgrade_to_pro".tr),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 30,)
                    ],
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
