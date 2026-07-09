import 'package:collection/collection.dart';
import 'package:crm/data/clients/client_provider.dart';
import 'package:core/dndservice/models/dnd_payload.dart';
import 'package:core/dndservice/models/dnd_payload_type.dart';
import 'package:core/dndservice/widgets/dnd_sender.dart';
import 'package:core/dndservice/widgets/drag_feedback_builders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/models/tasks_model.dart';
import 'package:tms_app/todo/provider/task_labels_provider.dart';
import 'package:core/user/user/user_provider.dart';
import 'package:intl/intl.dart';

class TaskCardWidget extends ConsumerWidget {
  final Tasks task;
  final bool readOnly;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final labels = ref.watch(taskLabelsProvider)?.results ?? [];
    final userState = ref.watch(userProvider);
    final clientList = ref.watch(clientProvider);
    final assignedClient = clientList.when(
      data:
          (clients) => clients.firstWhereOrNull((c) => c.id == task.assignedTo),
      loading: () => null,
      error: (e, _) => null,
    );

    List<Widget> memberAvatars = [];
    userState.maybeWhen(
      data: (userData) {
        if (userData != null) {
          final selectedMembers =
              userData.companyMembers
                  .where((m) => (task.members ?? []).contains(m.id))
                  .toList();

          final displayMembers = selectedMembers.take(2).toList();
          final remainingCount = selectedMembers.length - displayMembers.length;

          memberAvatars =
              displayMembers.map((member) {
                final avatar = member.avatar;
                final initials =
                    (member.firstName.isNotEmpty ? member.firstName[0] : '') +
                    (member.lastName.isNotEmpty ? member.lastName[0] : '');
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey[700],
                    backgroundImage:
                        avatar != null && avatar.isNotEmpty
                            ? NetworkImage(avatar)
                            : null,
                    child:
                        (avatar == null || avatar.isEmpty)
                            ? Text(
                              initials.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : null,
                  ),
                );
              }).toList();

          if (remainingCount > 0) {
            memberAvatars.add(
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[700],
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }
        }
      },
      orElse: () {},
    );

    List<Widget> labelColors = [];
    if (labels.isNotEmpty && (task.labels?.isNotEmpty ?? false)) {
      labelColors =
          task.labels!.map((id) {
            final label = labels.firstWhereOrNull((l) => l.id == id);
            if (label != null) {
              final color = Color(
                int.parse(label.color.replaceFirst('#', '0xff')),
              );
              return Container(
                width: 30,
                height: 5,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }
            return const SizedBox.shrink();
          }).toList();
    }

    String deadline = '';
    if (task.deadline != null && task.deadline!.isNotEmpty) {
      try {
        final date = DateTime.parse(task.deadline!).toLocal();
        deadline = DateFormat('d MMM').format(date);
      } catch (_) {}
    }

    int completedChecklistItems = 0;
    int totalChecklistItems = 0;
    if (task.tmsTaskChecklist != null && task.tmsTaskChecklist!.isNotEmpty) {
      totalChecklistItems = task.tmsTaskChecklist!.fold(
        0,
        (sum, checklist) => sum + checklist.checklist.length,
      );
      completedChecklistItems = task.tmsTaskChecklist!.fold(
        0,
        (sum, checklist) =>
            sum + checklist.checklist.where((e) => e.completed).length,
      );
    }
    DateTime? deadlineDate;
    if (task.deadline != null && task.deadline!.isNotEmpty) {
      try {
        deadlineDate = DateTime.parse(task.deadline!).toLocal();
      } catch (_) {}
    }

    const int warnDays = 2;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final bool isOverdue =
        deadlineDate != null && deadlineDate.isBefore(startOfToday);

    Color badgeBg = theme.themeColor;

    if (deadlineDate != null && !isOverdue) {
      final remaining = deadlineDate.difference(startOfToday).inDays;
      if (remaining <= warnDays) {
        badgeBg = Colors.amber;
      } else {
        badgeBg = Colors.green;
      }
    }
    final card = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          color: theme.adPopBackground.withAlpha((255 * 0.7).toInt()),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      if (task.priority != null &&
                          task.priority!.isNotEmpty) ...[
                        Icon(
                          Icons.flag,
                          size: 18,
                          color:
                              task.priority == 'H'
                                  ? Colors.red
                                  : task.priority == 'M'
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                        SizedBox(width: 10),
                      ],
                      if (labelColors.isNotEmpty) ...[
                        Expanded(
                          child: SingleChildScrollView(
                            reverse: true,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: labelColors,
                            ),
                          ),
                        ),
                      ] else ...[
                        Spacer(),
                      ],

                      if (task.isCompleted == true)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Colors.green, // or theme color for completed
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  task.name ?? '',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (assignedClient != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${"Assigned To".tr}: ${assignedClient.name}',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                if (deadline.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: theme.themeTextColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          deadline,
                          style: TextStyle(
                            color: theme.themeTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (task.commentsCount != null &&
                        task.commentsCount! > 0) ...[
                      Icon(
                        Icons.comment_outlined,
                        color: theme.textColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.commentsCount}',
                        style: TextStyle(color: theme.textColor, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (totalChecklistItems > 0) ...[
                      Icon(
                        Icons.check_box_outlined,
                        color: theme.textColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$completedChecklistItems/$totalChecklistItems',
                        style: TextStyle(color: theme.textColor, fontSize: 12),
                      ),
                    ],
                    if (task.metaFields?.emmaPending == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF37B6FF).withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: const Color(0xFF37B6FF).withAlpha(120),
                              width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                size: 10, color: Color(0xFF37B6FF)),
                            const SizedBox(width: 3),
                            const Text(
                              'Emma',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xFF37B6FF)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    ...memberAvatars,
                  ],
                ),
              ],
            ),
          ),
        ),
      );

    if (readOnly) {
      return card;
    }

    return DndSender(
      useLongPress: true,
      payload: DndPayload(
        type: DndPayloadType.task,
        id: task.id.toString(),
      ),
      feedbackBuilder: (context) =>
          DragFeedbackBuilders.taskFeedback(context, task.name ?? 'Task'),
      child: card,
    );
  }
}
