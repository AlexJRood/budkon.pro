import 'package:collection/collection.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/design.dart';
import 'package:tms_app/todo/board/provider/board_details_provider.dart';
import 'package:tms_app/todo/board/provider/board_provider.dart';
import 'package:core/user/user/user_provider.dart';
import '../../../data/sidebar_data.dart';
import '../../provider/todo_provider.dart';
import 'assign_dialog_widget.dart';
import 'checklist_dialog_widget.dart';
import 'copy_task_dialog_widget.dart';
import 'label_dialog_widget.dart';
import 'members_dialog_widget.dart';
import 'move_task_dialog_widget.dart';
import 'text_button_with_icon.dart';
import 'package:flutter/foundation.dart';

class SidebarOptions extends ConsumerWidget {
  final String taskId;
  const SidebarOptions({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final allTasks = ref.watch(taskDetailsProvider);
    final task = allTasks.firstWhereOrNull((t) => t.id.toString() == taskId);
    final isCompleted = task?.isCompleted ?? false;
    final user = ref.watch(
      userProvider,
    ).maybeWhen(data: (u) => u, orElse: () => null);
    final int? currentUserId = int.tryParse(user?.userId ?? '');
    final List<int> memberIds = (task?.members ?? const [])
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .toList();
    final bool isMember =
        currentUserId != null && memberIds.contains(currentUserId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sidebarData.map((item) {
          if (item['id'] == 'join') {
            final label = isMember ? 'Leave'.tr : 'Join'.tr;
            final IconData icon =
            isMember
                ? Icons.person_remove_alt_1
                : Icons.person_add_alt_1;

            return TextButtonWithIcon(
              label: label,
              icon: icon,
              onTap: () => _handleButtonTap(
                context,
                ref,
                isMember ? 'leave' : 'join',
                theme,
              ),
            );
          }

          if (item['type'] == 'header') {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                item['title']!.toString().tr,
                style: AppTextStyles.interMedium14.copyWith(
                  color: theme.textColor,
                ),
              ),
            );
          } else if (item['id'] == 'copy') {
            return Column(
              children: [
                TextButtonWithIcon(
                  label: item['title']!.toString().tr,
                  icon: item['icon'] as IconData?,
                  onTap: () =>
                      _handleButtonTap(context, ref, 'copy', theme),
                ),
                const SizedBox(height: 8),
                TextButtonWithIcon(
                  label: 'Checklist'.tr,
                  icon: Icons.checklist,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => ChecklistDialogWidget(taskId: taskId),
                    );
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      backgroundColor:
                      isCompleted ? Colors.green : theme.themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final allTasks = ref.read(taskDetailsProvider);
                      final task = allTasks.firstWhereOrNull(
                            (t) => t.id.toString() == taskId,
                      );
                      final currentStatus = task?.isCompleted ?? false;
                      final newValue = !currentStatus;
                      ref
                          .read(taskDetailsProvider.notifier)
                          .updateTask(taskId, 'is_completed', newValue);
                      try {
                        await ref
                            .read(taskProvider.notifier)
                            .editTask(
                          context,
                          taskId,
                          'is_completed',
                          newValue,
                        );
                      } catch (e) {
                        ref
                            .read(taskDetailsProvider.notifier)
                            .updateTask(
                          taskId,
                          'is_completed',
                          currentStatus,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update: $e')),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: theme.themeTextColor,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCompleted
                              ? 'Mark Incomplete'.tr
                              : 'Mark Complete'.tr,
                          style: AppTextStyles.interSemiBold14.copyWith(
                            color: theme.themeTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          } else {
            if (item['id'] == 'assign') {
              final assignedClientId = task?.assignedTo;
              final clientList = ref.watch(clientProvider);
              final assignedClient = clientList.when(
                data:
                    (clients) => clients.firstWhereOrNull(
                      (c) => c.id == assignedClientId,
                ),
                loading: () => null,
                error: (e, _) => null,
              );

              return TextButtonWithIcon(
                label:
                assignedClient != null
                    ? '${"Assigned To".tr}: ${_limitText(assignedClient.name)}'
                    : 'Assign to Client'.tr,
                icon: item['icon'] as IconData?,
                onTap: () =>
                    _handleButtonTap(context, ref, 'assign', theme),
              );
            }

            return TextButtonWithIcon(
              label: item['title']!.toString().tr,
              icon: item['icon'] as IconData?,
              onTap: () => _handleButtonTap(
                context,
                ref,
                item['id']!.toString(),
                theme,
              ),
            );
          }
        }),
      ],
    );
  }

  String _limitText(String text, [int maxLength = 15]) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  void _handleButtonTap(
      BuildContext context,
      WidgetRef ref,
      String action,
      ThemeColors theme,
      ) async {
    try {
      switch (action) {
        case 'join':
        case 'leave':
          final user = ref.read(userProvider).maybeWhen(
            data: (u) => u,
            orElse: () => null,
          );
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User data not loaded'.tr)),
            );
            break;
          }

          final userId = int.tryParse(user.userId);
          if (userId == null) break;

          final task = ref
              .read(taskDetailsProvider)
              .firstWhereOrNull((t) => t.id.toString() == taskId);

          final currentMemberIds = task?.members
              ?.map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toList() ??
              [];

          final oldMembers = List<int>.from(currentMemberIds);
          final updated = List<int>.from(currentMemberIds);

          if (updated.contains(userId)) {
            updated.remove(userId);
          } else {
            updated.add(userId);
          }

          ref.read(taskDetailsProvider.notifier).updateTask(taskId, 'members', updated);

          try {
            await ref.read(taskProvider.notifier).editTask(
              context,
              taskId,
              'members',
              updated,
            );
          } catch (e) {
            ref.read(taskDetailsProvider.notifier).updateTask(taskId, 'members', oldMembers);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update task: $e')),
            );
          }
          break;

        case 'members':
          ref.read(searchMembersQueryProvider.notifier).state = '';
          await showDialog(
            context: context,
            builder: (_) => MembersDialogWidget(taskId: taskId),
          );
          break;

        case 'label':
          showDialog(
            context: context,
            builder: (_) => LabelDialogWidget(taskId: taskId),
          );
          break;

        case 'attachment':
          await ref.read(taskDetailsProvider.notifier).addFileToTask(taskId);
          break;

        case 'move':
          ref.read(selectedProgressIdProvider.notifier).state = null;
          showDialog(
            context: context,
            builder: (_) => MoveTaskWidget(taskId: taskId),
          );
          break;

        case 'copy':
          ref.read(selectedProgressIdProvider.notifier).state = null;
          showDialog(
            context: context,
            builder: (_) => CopyTaskWidget(taskId: taskId),
          );
          break;

        case 'delete':
          await ref
              .read(taskDetailsProvider.notifier)
              .deleteTask(context, taskId)
              .whenComplete(() async {
            await ref
                .read(boardDetailsManagementProvider.notifier)
                .fetchBoardDetails(
              ref.watch(boardIdProvider).toString(),
            );
            if (context.mounted) Navigator.pop(context);
          });
          break;

        case 'assign':
          await showDialog(
            context: context,
            builder: (_) => AssignDialogWidget(taskId: taskId),
          );
          await ref.read(taskDetailsProvider.notifier).fetchTaskFiles(taskId);
          break;
      }
    } catch (e) {
      if (kDebugMode) print('Error in _handleButtonTap: $e');
    }
  }
}