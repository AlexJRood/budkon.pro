import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:core/user/user/user_provider.dart';

class MembersDialogWidget extends ConsumerWidget {
  final String taskId;
  const MembersDialogWidget({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final user = ref.watch(userProvider).value;
    final searchQuery = ref.watch(searchMembersQueryProvider);
    final searchNotifier = ref.read(searchMembersQueryProvider.notifier);
    final allTasks = ref.watch(taskDetailsProvider);
    final task = allTasks.firstWhereOrNull((t) => t.id.toString() == taskId);

    if (user == null || task == null) return const SizedBox();

    final selectedIds =
        (task.members ?? [])
            .map((e) => int.tryParse(e.toString()))
            .whereType<int>()
            .toList();

    final filteredMembers =
        user.companyMembers
            .where(
              (e) =>
                  e.firstName.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ||
                  e.lastName.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

    return Dialog(
      backgroundColor: theme.adPopBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => searchNotifier.state = val,
              cursorColor: theme.textColor,
              decoration: InputDecoration(
                hintText: 'Search members...'.tr,
                hintStyle: TextStyle(
                  color: theme.textColor
                ),
                prefixIcon: Icon(Icons.search, color: theme.textColor),
                filled: true,
                fillColor: theme.textFieldColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.themeColor),
                ),
              ),
              style: TextStyle(color: theme.textColor),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                addAutomaticKeepAlives: false,
                cacheExtent: 300.0,
                itemCount: filteredMembers.length,
                itemBuilder: (_, index) {
                  final member = filteredMembers[index];
                  final int? memberId = int.tryParse(member.id.toString());
                  if (memberId == null) return const SizedBox.shrink();

                  final isSelected = selectedIds.contains(memberId);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: InkWell(
                      onTap: () async {
                        final updated = List<int>.from(selectedIds);

                        if (isSelected) {
                          updated.remove(memberId);
                        } else {
                          updated.add(memberId);
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
                          ref.read(taskDetailsProvider.notifier).updateTask(taskId, 'members', selectedIds);
                          debugPrint('Failed to update members: $e');
                        }
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            activeColor: theme.themeColor,
                            checkColor: theme.themeTextColor,
                            value: isSelected,
                            onChanged: (val) async {
                              final updated = List<int>.from(selectedIds);

                              if (val == true) {
                                if (!updated.contains(memberId)) {
                                  updated.add(memberId);
                                }
                              } else {
                                updated.remove(memberId);
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
                                ref.read(taskDetailsProvider.notifier).updateTask(taskId, 'members', selectedIds);
                                debugPrint('Failed to update members: $e');
                              }
                            },
                          ),
                          Expanded(
                            child: Text(
                              '${member.firstName} ${member.lastName}',
                              style: TextStyle(color: theme.textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
