import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import '../../provider/send_form_provider.dart';

import 'package:get/get_utils/get_utils.dart';

final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

class DateTimePickerWidget extends ConsumerWidget {
  final bool isMobile;
  const DateTimePickerWidget({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(addClientFormProvider);
    final formNotifier = ref.read(addClientFormProvider.notifier);
    final theme = ref.watch(themeColorsProvider);
    final startTime = formState.eventStartTime;
    final endTime = formState.eventEndTime;

    return isMobile
        ? Column(
          children: [
            BuildPickBox(
              label:
                  startTime != null
                      ? startTime.format(context)
                      : "Start Time".tr,
              icon: Icons.access_time,
              onTap: () async {
                final pickedTime = await _pickTime(context, startTime, ref);
                if (pickedTime != null) {
                  formNotifier.setStartTime(pickedTime);
                }
              },
            ),
            const SizedBox(height: 10),
            BuildPickBox(
              label: endTime != null ? endTime.format(context) : "End Time".tr,
              icon: Icons.access_time,
              onTap: () async {
                final pickedTime = await _pickTime(context, endTime, ref);
                if (pickedTime != null) {
                  formNotifier.setEndTime(pickedTime);
                }
              },
            ),
          ],
        )
        : Row(
          children: [
            const SizedBox(width: 8),
            Text(
              "from",
              style: TextStyle(color: theme.textColor, fontSize: 16),
            ),
            const SizedBox(width: 8),
            BuildPickBox(
              label:
                  startTime != null
                      ? startTime.format(context)
                      : "Start Time".tr,
              icon: Icons.access_time,
              onTap: () async {
                final pickedTime = await _pickTime(context, startTime, ref);
                if (pickedTime != null) {
                  formNotifier.setStartTime(pickedTime);
                }
              },
            ),
            const SizedBox(width: 8),
            Text("to", style: TextStyle(color: theme.textColor, fontSize: 16)),
            const SizedBox(width: 8),
            BuildPickBox(
              label: endTime != null ? endTime.format(context) : "End Time".tr,
              icon: Icons.access_time,
              onTap: () async {
                final pickedTime = await _pickTime(context, endTime, ref);
                if (pickedTime != null) {
                  formNotifier.setEndTime(pickedTime);
                }
              },
            ),
          ],
        );
  }

  Future<TimeOfDay?> _pickTime(
    BuildContext context,
    TimeOfDay? initialTime,
    WidgetRef ref,
  ) async {
    final themeMode = ref.watch(themeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: isDark ? ThemeData.light() : ThemeData.dark(),
          child: child!,
        );
      },
    );
  }
}

class BuildPickBox extends ConsumerWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const BuildPickBox({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.themeColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: theme.dashboardContainer, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: theme.dashboardContainer, size: 18),
          ],
        ),
      ),
    );
  }
}
