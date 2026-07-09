import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:tms_app/todo/view/widgets/quick_access_option.dart';
import 'package:tms_app/todo/view/widgets/text_button_with_icon.dart';

class DueDateSelector extends ConsumerWidget {
  final DateTime? initialDueDate;
  final int taskId;

  const DueDateSelector({
    super.key,
    required this.initialDueDate,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueDate = ref.watch(dueDateProvider(initialDueDate));
    final notifier = ref.read(dueDateProvider(initialDueDate).notifier);
    final theme = ref.watch(themeColorsProvider);

    void pickDueDate() async {
      final now = DateTime.now();

      final initial = dueDate ?? now;

      final first =
          initial.isBefore(now)
              ? initial
              : now;

      final last = DateTime(now.year + 5);

      final selected = await showDatePicker(
        useRootNavigator: true,
        context: context,
        initialDate: initial,
        firstDate: first,
        lastDate: last,
        confirmText: 'OK'.tr,
        cancelText: 'Cancel'.tr,
        helpText: 'Choose date'.tr,
        fieldHintText: 'dd.MM.yyyy'.tr,
        fieldLabelText: 'Enter date'.tr,
        builder: (context, child) {
          final base = Theme.of(context);
          final isDark = base.brightness == Brightness.dark;

          final scheme = (isDark
                  ? const ColorScheme.dark()
                  : const ColorScheme.light())
              .copyWith(
                primary: theme.themeColor,
                onPrimary: theme.themeTextColor,
                surface: theme.adPopBackground,
                onSurface: theme.textColor,
              );

          return Theme(
            data: base.copyWith(
              colorScheme: scheme,
              dialogTheme: DialogThemeData(
                backgroundColor: theme.adPopBackground,
                surfaceTintColor: Colors.transparent,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: theme.textFieldColor,
                hintStyle: TextStyle(color: theme.textColor.withOpacity(0.7)),
                labelStyle: TextStyle(color: theme.textColor),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.themeColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.themeColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.themeColor, width: 2),
                ),
              ),
              datePickerTheme: DatePickerThemeData(
                backgroundColor: theme.adPopBackground,
                headerBackgroundColor: theme.themeColor,
                headerForegroundColor: theme.themeTextColor,
                dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? theme.themeTextColor
                      : theme.textColor;
                }),
                dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? theme.themeColor
                      : Colors.transparent;
                }),
                todayBorder: BorderSide(color: theme.themeColor),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: theme.themeColor),
              ),
            ),
            child: child!,
          );
        },
      );

      if (selected != null) {
        final utcMidnight = DateTime.utc(
          selected.year,
          selected.month,
          selected.day,
        );

        notifier.setDueDate(selected);

        await ref
            .read(taskProvider.notifier)
            .editTask(
              context,
              taskId.toString(),
              'deadline',
              utcMidnight.toIso8601String(),
            )
            .whenComplete(() {
              ref
                  .read(taskDetailsProvider.notifier)
                  .updateTask(taskId.toString(), 'deadline', selected);
            });
      }
    }

    final due = dueDate?.toLocal();
    final label =
        due != null
            ? '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}'
            : 'Select Due Date'.tr;

    return QuickAccessOption(
      'Due Date'.tr,
      TextButtonWithIcon(
        label: label,
        onTap: pickDueDate,
        icon: Icons.date_range,
      ),
    );
  }
}
