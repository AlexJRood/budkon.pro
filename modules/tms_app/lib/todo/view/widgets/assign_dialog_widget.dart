import 'package:collection/collection.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/theme/lottie.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';

class AssignDialogWidget extends ConsumerWidget {
  final String taskId;
  const AssignDialogWidget({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final clientListAsyncValue = ref.watch(clientProvider);
    final allTasks = ref.watch(taskDetailsProvider);
    final task = allTasks.firstWhereOrNull((t) => t.id.toString() == taskId);
    final assignedClientId = task?.assignedTo;

    return Dialog(
      backgroundColor: theme.adPopBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 560,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign to Client'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: clientListAsyncValue.when(
                data: (clients) {
                  if (clients.isEmpty) {
                    return Center(
                      child: Text(
                        'No clients found',
                        style: TextStyle(color: theme.textColor),
                      ),
                    );
                  }
                  return ListView.separated(
                    separatorBuilder:
                        (_, __) => Divider(color: theme.themeColor),
                    itemCount: clients.length,
                    itemBuilder: (_, index) {
                      final client = clients[index];
                      final isSelected = assignedClientId == client.id;

                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          await ref
                              .read(taskProvider.notifier)
                              .assignTaskToClient(
                                taskId.toString(),
                                client.id.toString(),
                              );
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? theme.themeColor.withAlpha(38)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: theme.themeColor,
                                )
                              else
                                Icon(
                                  Icons.circle_outlined,
                                  color: theme.textColor.withAlpha(128),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${client.name} ${client.lastName}',
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 16,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => Center(child: AppLottie.loading()),
                error:
                    (e, st) => Center(
                      child: Text(
                        'Error loading clients',
                        style: TextStyle(color: theme.textColor),
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
