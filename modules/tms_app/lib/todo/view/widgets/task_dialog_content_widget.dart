import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/models/tasks_model.dart';
import 'package:tms_app/todo/provider/task_labels_provider.dart';
import 'package:tms_app/todo/provider/todo_provider.dart';
import 'package:tms_app/todo/view/widgets/priority_selector_widget.dart';
import 'package:tms_app/todo/view/widgets/quick_access_option.dart';
import 'package:tms_app/todo/view/widgets/side_bar_options.dart';
import 'package:core/user/user/user_provider.dart';

import 'attachment_display_widget.dart';
import 'checklist_section_widget.dart';
import 'comment_field.dart';
import 'description_editor_widget.dart';
import 'due_date_selector_widget.dart';
import 'label_selector_widget.dart';
import 'package:intl/intl.dart';

class DialogContent extends ConsumerStatefulWidget {
  final Tasks task;

  const DialogContent({super.key, required this.task});

  @override
  ConsumerState<DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends ConsumerState<DialogContent> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(taskLabelsProvider.notifier).fetchLabels();
      ref
          .read(commentsProvider.notifier)
          .fetchComments(widget.task.id.toString(), ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider);
    final taskDetails = ref.watch(taskDetailsProvider);

    final currentTask = taskDetails.firstWhereOrNull(
          (t) => t.id.toString() == widget.task.id.toString(),
    );

    final attachments = currentTask?.files ?? [];
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 1080;
    final theme = ref.read(themeColorsProvider);

    return isMobile
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainContent(
              context,
              attachments,
              comments,
              isMobile,
              theme,
              widget.task.id.toString(),
            ),
          ],
        )
        : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _buildMainContent(
                context,
                attachments,
                comments,
                isMobile,
                theme,
                widget.task.id.toString(),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: SidebarOptions(taskId: widget.task.id.toString()),
            ),
          ],
        );
  }

  Widget _buildMainContent(
    BuildContext context,
    List<dynamic>? attachments,
    List<dynamic> comments,
    bool isMobile,
    dynamic theme,
    String taskId,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final theme = ref.watch(themeColorsProvider);
        final tasks = ref.watch(taskDetailsProvider);
        final task = tasks.firstWhereOrNull((t) => t.id == widget.task.id);

        final checklists = task?.tmsTaskChecklist ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SidebarOptions(taskId: widget.task.id.toString()),
                  const SizedBox(height: 20),
                  LabelSelectorWidget(taskId: widget.task.id.toString()),
                  DueDateSelector(
                    initialDueDate:
                        widget.task.deadline != null
                            ? DateTime.parse(widget.task.deadline!)
                            : null,
                    taskId: widget.task.id!,
                  ),
                  PrioritySelector(
                    initialPriority: widget.task.priority!,
                    taskId: widget.task.id!,
                  ),
                  Row(
                    children: [
                      QuickAccessOption(
                        'Member'.tr,
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 3,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add, color: theme.textColor),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.textFieldColor.withAlpha(
                                (255 * 0.3).toInt(),
                              ),
                            ),
                            onPressed: () {
                              final user = ref
                                  .read(userProvider)
                                  .maybeWhen(
                                    data: (u) => u,
                                    orElse: () => null,
                                  );

                              if (user == null) {
                                debugPrint('❌ Cannot update task, user not loaded');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User data not loaded'),
                                  ),
                                );
                                return;
                              }

                              final userId = int.tryParse(user.userId);
                              if (userId == null) return;

                              final allTasks = ref.read(taskDetailsProvider);
                              final task = allTasks.firstWhereOrNull(
                                (t) =>
                                    t.id.toString() ==
                                    widget.task.id.toString(),
                              );

                              /// ✅ Always start from latest task members from backend
                              final currentMemberIds =
                                  task?.members
                                      ?.map((e) => int.tryParse(e.toString()))
                                      .whereType<int>()
                                      .toList() ??
                                  [];

                              final updated = [...currentMemberIds];

                              if (updated.contains(userId)) {
                                updated.remove(userId);
                                debugPrint('Removed user id $userId from task');
                              } else {
                                updated.add(userId);
                                debugPrint('Added user id $userId to task');
                              }

                              /// ✅ No need to touch selectedMemberIdsProvider anymore, direct API call
                              ref
                                  .read(taskProvider.notifier)
                                  .editTask(
                                    context,
                                    widget.task.id.toString(),
                                    'members',
                                    updated,
                                  )
                                  .whenComplete(() {
                                    ref
                                        .read(taskDetailsProvider.notifier)
                                        .updateTask(
                                          widget.task.id.toString(),
                                          'members',
                                          updated,
                                        );
                                  });
                              debugPrint('✅ Final updated members list: $updated');
                            },
                          ),
                        ),
                      ),

                      Consumer(
                        builder: (context, ref, _) {
                          final theme = ref.watch(themeColorsProvider);
                          final userState = ref.watch(userProvider);
                          final allTasks = ref.watch(taskDetailsProvider);

                          final updatedTask = allTasks.firstWhereOrNull(
                            (t) => t.id.toString() == widget.task.id.toString(),
                          );

                          if (userState is AsyncData &&
                              userState.value != null &&
                              updatedTask != null) {
                            final user = userState.value!;
                            final taskMemberIds =
                                updatedTask.members
                                    ?.map((e) => int.tryParse(e.toString()))
                                    .whereType<int>()
                                    .toList() ??
                                [];

                            final selectedMembers =
                                user.companyMembers
                                    .where(
                                      (member) =>
                                          taskMemberIds.contains(member.id),
                                    )
                                    .toList();

                            final displayMembers =
                                selectedMembers.take(2).toList();
                            final remainingCount =
                                selectedMembers.length - displayMembers.length;

                            return Row(
                              children: [
                                ...displayMembers.map((member) {
                                  final avatarUrl = member.avatar;
                                  final initials =
                                      (member.firstName.isNotEmpty
                                          ? member.firstName[0]
                                          : '') +
                                      (member.lastName.isNotEmpty
                                          ? member.lastName[0]
                                          : '');
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.grey[700],
                                      backgroundImage:
                                          avatarUrl != null &&
                                                  avatarUrl.isNotEmpty
                                              ? NetworkImage(avatarUrl)
                                              : null,
                                      child:
                                          (avatarUrl == null ||
                                                  avatarUrl.isEmpty)
                                              ? Text(
                                                initials.toUpperCase(),
                                                style: TextStyle(
                                                  color: theme.textColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                              : null,
                                    ),
                                  );
                                }),
                                if (remainingCount > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.grey[700],
                                      child: Text(
                                        '+$remainingCount',
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 15),
                  Row(
                    children: [
                      Consumer(
                        builder: (context, ref, _) {
                          final theme = ref.watch(themeColorsProvider);
                          final userState = ref.watch(userProvider);
                          final allTasks = ref.watch(taskDetailsProvider);

                          final updatedTask = allTasks.firstWhereOrNull(
                            (t) => t.id.toString() == widget.task.id.toString(),
                          );

                          if (userState is AsyncData &&
                              userState.value != null &&
                              updatedTask != null) {
                            final user = userState.value!;
                            final taskMemberIds =
                                updatedTask.members
                                    ?.map((e) => int.tryParse(e.toString()))
                                    .whereType<int>()
                                    .toList() ??
                                [];

                            final selectedMembers =
                                user.companyMembers
                                    .where(
                                      (member) =>
                                          taskMemberIds.contains(member.id),
                                    )
                                    .toList();

                            final displayMembers =
                                selectedMembers.take(2).toList();
                            final remainingCount =
                                selectedMembers.length - displayMembers.length;

                            return Row(
                              children: [
                                ...displayMembers.map((member) {
                                  final avatarUrl = member.avatar;
                                  final initials =
                                      (member.firstName.isNotEmpty
                                          ? member.firstName[0]
                                          : '') +
                                      (member.lastName.isNotEmpty
                                          ? member.lastName[0]
                                          : '');
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.grey[700],
                                      backgroundImage:
                                          avatarUrl != null &&
                                                  avatarUrl.isNotEmpty
                                              ? NetworkImage(avatarUrl)
                                              : null,
                                      child:
                                          (avatarUrl == null ||
                                                  avatarUrl.isEmpty)
                                              ? Text(
                                                initials.toUpperCase(),
                                                style: TextStyle(
                                                  color: theme.textColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                              : null,
                                    ),
                                  );
                                }),
                                if (remainingCount > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.grey[700],
                                      child: Text(
                                        '+$remainingCount',
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                      QuickAccessOption(
                        'Member'.tr,
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 3,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add, color: theme.textColor),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.textFieldColor.withAlpha(
                                (255 * 0.3).toInt(),
                              ),
                            ),
                            onPressed: () {
                              final user = ref
                                  .read(userProvider)
                                  .maybeWhen(
                                    data: (u) => u,
                                    orElse: () => null,
                                  );

                              if (user == null) {
                                debugPrint('❌ Cannot update task, user not loaded');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User data not loaded'),
                                  ),
                                );
                                return;
                              }

                              final userId = int.tryParse(user.userId);
                              if (userId == null) return;

                              final allTasks = ref.read(taskDetailsProvider);
                              final task = allTasks.firstWhereOrNull(
                                (t) =>
                                    t.id.toString() ==
                                    widget.task.id.toString(),
                              );

                              /// ✅ Always start from latest task members from backend
                              final currentMemberIds =
                                  task?.members
                                      ?.map((e) => int.tryParse(e.toString()))
                                      .whereType<int>()
                                      .toList() ??
                                  [];

                              final updated = [...currentMemberIds];

                              if (updated.contains(userId)) {
                                updated.remove(userId);
                                debugPrint('Removed user id $userId from task');
                              } else {
                                updated.add(userId);
                                debugPrint('Added user id $userId to task');
                              }

                              /// ✅ No need to touch selectedMemberIdsProvider anymore, direct API call
                              ref
                                  .read(taskProvider.notifier)
                                  .editTask(
                                    context,
                                    widget.task.id.toString(),
                                    'members',
                                    updated,
                                  )
                                  .whenComplete(() {
                                    ref
                                        .read(taskDetailsProvider.notifier)
                                        .updateTask(
                                          widget.task.id.toString(),
                                          'members',
                                          updated,
                                        );
                                  });
                              debugPrint('✅ Final updated members list: $updated');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  LabelSelectorWidget(taskId: widget.task.id.toString()),

                  DueDateSelector(
                    initialDueDate:
                        widget.task.deadline != null
                            ? DateTime.parse(widget.task.deadline!).toLocal()
                            : null,
                    taskId: widget.task.id!,
                  ),
                  PrioritySelector(
                    initialPriority: widget.task.priority!,
                    taskId: widget.task.id!,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 30),
            DescriptionEditor(
              initialDescription: widget.task.description,
              taskId: widget.task.id!,
            ),

            if (attachments!.isNotEmpty) const SizedBox(height: 40),
            if (attachments.isNotEmpty)
              AttachmentDisplay(ref: ref, taskId: widget.task.id.toString()),
            const SizedBox(height: 40),
            if (checklists.isNotEmpty) ...[
              ...checklists.map(
                (checklist) => ChecklistSection(
                  checklist: checklist,
                  onChecklistUpdated: (updatedItems) {
                    final updatedChecklist = checklist.copyWith(
                      checklist: updatedItems,
                    );
                    final updatedList =
                        checklists
                            .map(
                              (c) =>
                                  c.id == checklist.id ? updatedChecklist : c,
                            )
                            .toList();

                    ref
                        .read(taskDetailsProvider.notifier)
                        .updateTask(taskId, 'tms_task_checklist', updatedList);
                  },
                  taskId: widget.task.id.toString(),
                ),
              ),
              const SizedBox(height: 30),
            ] else ...[
              const SizedBox(),
            ],
            const SizedBox(height: 20),
            CommentField(taskId: widget.task.id.toString()),
            const SizedBox(height: 20),
            comments.isEmpty
                ? Center(
                  child: Text(
                    'No comments available.'.tr,
                    style: TextStyle(color: theme.textColor),
                  ),
                )
                : SizedBox(
                  height: context.height * 0.5,
                  child: ListView.builder(
                    addAutomaticKeepAlives: false,
                    cacheExtent: 300.0,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      if (index < 0 || index >= comments.length) {
                        return const SizedBox();
                      }
                      final data = comments[index];
                      final tsText = _formatMDY(data.timestamp);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.textFieldColor,
                              backgroundImage:
                                  (data.user.avatar != null &&
                                          data.user.avatar!.isNotEmpty)
                                      ? NetworkImage(data.user.avatar!)
                                      : null,
                              child:
                                  (data.user.avatar == null ||
                                          data.user.avatar!.isEmpty)
                                      ? Text(
                                        data.user.firstName.isNotEmpty
                                            ? data.user.firstName[0]
                                                .toUpperCase()
                                            : '',
                                        style: TextStyle(
                                          color: theme.textColor,
                                        ),
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 12),

                            // Comment Box + Actions
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Username + timestamp
                                  Row(
                                    children: [
                                      Text(
                                        data.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        tsText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textColor.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Comment Box (mentions highlighted)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.textFieldColor,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.textColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          offset: const Offset(2, 2),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: MentionText(
                                      text: data.comment,
                                      baseStyle: TextStyle(
                                        color: theme.textColor,
                                      ),
                                      clientStyle: TextStyle(
                                        color: theme.themeColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      memberStyle: TextStyle(
                                        color: theme.themeColor,
                                        fontWeight: FontWeight.w800,
                                        backgroundColor: theme.themeColor
                                            .withValues(alpha: 0.12),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Delete Button
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.alternate_email,
                                        size: 16,
                                        color: theme.textColor.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          minimumSize: Size.zero,
                                          padding: EdgeInsets.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(commentsProvider.notifier)
                                              .deleteComment(
                                                widget.task.id!,
                                                data.id,
                                              );
                                        },
                                        child: Text(
                                          'Delete'.tr,
                                          style: TextStyle(
                                            color: theme.textColor.withValues(
                                              alpha: 0.8,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          ],
        );
      },
    );
  }

  String _formatMDY(dynamic ts) {
    if (ts == null) return '';
    DateTime? dt;

    if (ts is DateTime) {
      dt = ts;
    } else if (ts is int) {
      // if backend sends epoch (ms)
      dt = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true);
    } else if (ts is String) {
      // try ISO-8601 first
      dt = DateTime.tryParse(ts);
      // common fallback: "YYYY-MM-DD HH:mm:ss"
      dt ??= DateTime.tryParse(ts.replaceFirst(' ', 'T'));
    }

    if (dt == null) return ts.toString();
    dt = dt.toLocal();
    return DateFormat('M/d/yyyy').format(dt); // e.g., 8/23/2025
  }
}

class MentionText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final TextStyle clientStyle; // for @Name
  final TextStyle memberStyle; // for @@Name

  const MentionText({
    super.key,
    required this.text,
    required this.baseStyle,
    required this.clientStyle,
    required this.memberStyle,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _buildMentionSpans(text, baseStyle, clientStyle, memberStyle);
    return Text.rich(
      TextSpan(children: spans, style: baseStyle),
      softWrap: true,
    );
  }

  List<TextSpan> _buildMentionSpans(
    String input,
    TextStyle base,
    TextStyle client,
    TextStyle member,
  ) {
    final mentionRegex = RegExp(r'@@([^\s@]+)|(?<!@)@([^\s@]+)');
    final spans = <TextSpan>[];
    int last = 0;

    for (final m in mentionRegex.allMatches(input)) {
      if (m.start > last) {
        spans.add(TextSpan(text: input.substring(last, m.start), style: base));
      }

      final full = m.group(0)!;
      final isMember = m.group(1) != null; // matched @@(...)
      spans.add(TextSpan(text: full, style: isMember ? member : client));

      last = m.end;
    }

    if (last < input.length) {
      spans.add(TextSpan(text: input.substring(last), style: base));
    }

    return spans;
  }
}
