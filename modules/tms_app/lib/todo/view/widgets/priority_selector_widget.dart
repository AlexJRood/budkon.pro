import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:tms_app/todo/view/widgets/quick_access_option.dart';
import 'package:tms_app/todo/view/widgets/text_button_with_icon.dart';

class PrioritySelector extends ConsumerWidget {
  final String initialPriority;
  final int taskId;

  const PrioritySelector({
    super.key,
    required this.initialPriority,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priority = ref.watch(priorityProvider(initialPriority));
    final notifier = ref.read(priorityProvider(initialPriority).notifier);
    final theme = ref.watch(themeColorsProvider);

    void showPriorityDialog() async {
      final result = await showDialog<String>(
        context: context,
        builder:
            (context) => SimpleDialog(
              backgroundColor: theme.adPopBackground,
              title: Text(
                "Select Priority".tr,
                style: AppTextStyles.interBold.copyWith(color: theme.textColor),
              ),
              children: [
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'H'),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.red),
                      const SizedBox(width: 10),
                      Text(
                        'High Priority'.tr,
                        style: AppTextStyles.interMedium.copyWith(
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'M'),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.orange),
                      const SizedBox(width: 10),
                      Text(
                        'Medium Priority'.tr,
                        style: AppTextStyles.interMedium.copyWith(
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'L'),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.green),
                      const SizedBox(width: 10),
                      Text(
                        'Low Priority'.tr,
                        style: AppTextStyles.interMedium.copyWith(
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      );

      if (result != null) {
        notifier.setPriority(result);
        await ref
            .read(taskProvider.notifier)
            .editTask(context, taskId.toString(), 'priority', result);
      }
    }

    Color iconColor =
        priority == 'H'
            ? Colors.red
            : priority == 'M'
            ? Colors.orange
            : Colors.green;

    String label =
        priority == 'H'
            ? 'High'.tr
            : priority == 'M'
            ? 'Medium'.tr
            : 'Low'.tr;

    return QuickAccessOption(
      'Priority'.tr,
      TextButtonWithIcon(
        label: label,
        icon: Icons.flag,
        iconColor: iconColor,
        onTap: showPriorityDialog,
      ),
    );
  }
}
