import 'dart:ui' as ui;

import 'package:core/ui/anchors/anchor_spec.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';
import 'package:tms_app/todo/view/widgets/task_dialog_content_widget.dart';

import '../models/tasks_model.dart';
import '../provider/todo_provider.dart';
import 'widgets/dialog_header.dart';

class TaskDetailsPopup extends ConsumerStatefulWidget {
  const TaskDetailsPopup({
    super.key,
    required this.task,
    this.scrollController,
    this.isMobile = false,
    this.readOnly = false,
  });

  final bool isMobile;
  final bool readOnly;
  final ScrollController? scrollController;
  final Tasks task;

  @override
  ConsumerState<TaskDetailsPopup> createState() => _TaskDetailsPopupState();
}

class _TaskDetailsPopupState extends ConsumerState<TaskDetailsPopup> {
  @override
  void initState() {
    super.initState();

    if (!widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(taskDetailsProvider.notifier)
            .fetchTaskFiles(widget.task.id.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final taskDetails =
        widget.readOnly ? <Tasks>[widget.task] : ref.watch(taskDetailsProvider);
    final theme = ref.read(themeColorsProvider);

    if (taskDetails.isEmpty) {
      return Center(child: CircularProgressIndicator(color: theme.themeColor));
    }

    final resolvedTask = taskDetails.last;
    final files = resolvedTask.files;
    final attachment =
        (files != null && files.isNotEmpty) ? files.last.file : null;
    final popupContent = EmmaUiAnchorTarget(
      // @emma-backend: EmmaAnchors.tmsTodoTaskPopupRoot
      anchorKey: 'tms.todo.task_popup.root',
      runtimeMode: EmmaUiAnchorRuntimeMode.always,
      tapMode: EmmaUiAnchorTapMode.disabled,
      child: Container(
        color: theme.adPopBackground.withAlpha((255 * 0.5).toInt()),
        width: widget.isMobile ? double.infinity : size.width * 0.75,
        height: widget.isMobile ? size.height * 0.9 : size.height * 0.8,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom:
                widget.isMobile
                    ? MediaQuery.of(context).viewInsets.bottom + 260
                    : 40,
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (attachment != null && attachment.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2.0),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              attachment,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      EmmaUiAnchorTarget(
                        // @emma-backend: EmmaAnchors.tmsTodoTaskPopupHeader
                        anchorKey: 'tms.todo.task_popup.header',
                        tapMode: EmmaUiAnchorTapMode.disabled,
                        child:
                            widget.readOnly
                                ? _ReadOnlyTaskHeader(
                                  task: resolvedTask,
                                  onClose: () => Navigator.pop(context),
                                )
                                : DialogHeader(
                                  task: resolvedTask,
                                  onClose: () => Navigator.pop(context),
                                ),
                      ),
                      const SizedBox(height: 25),
                      EmmaUiAnchorTarget(
                        // @emma-backend: EmmaAnchors.tmsTodoTaskPopupContent
                        anchorKey: 'tms.todo.task_popup.content',
                        tapMode: EmmaUiAnchorTapMode.disabled,
                        child:
                            widget.readOnly
                                ? _ReadOnlyTaskContent(task: resolvedTask)
                                : DialogContent(task: resolvedTask),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ],
        
        
        ),
    ),
      ),
    );

    return widget.isMobile
        ? ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: popupContent,
          ),
        )
        : Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: popupContent,
            ),
          ),
        );
  }
}

class _ReadOnlyTaskHeader extends ConsumerWidget {
  const _ReadOnlyTaskHeader({required this.task, required this.onClose});

  final VoidCallback onClose;
  final Tasks task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(
            color: task.isCompleted == true ? Colors.green : theme.themeColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.name ?? '',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'read_only_preview'.tr,
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.65),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: Icon(Icons.close, color: theme.textColor),
          tooltip: 'Close'.tr,
        ),
      ],
    );
  }
}

class _ReadOnlyTaskContent extends ConsumerWidget {
  const _ReadOnlyTaskContent({required this.task});

  final Tasks task;

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;

    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(parsed.day)}.${two(parsed.month)}.${parsed.year} '
        '${two(parsed.hour)}:${two(parsed.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    int checklistTotal = 0;
    int checklistCompleted = 0;
    final checklists = task.tmsTaskChecklist;
    if (checklists != null) {
      for (final checklist in checklists) {
        checklistTotal += checklist.checklist.length;
        checklistCompleted +=
            checklist.checklist.where((item) => item.completed).length;
      }
    }

    final members = task.members ?? const <int>[];
    final labels = task.labels ?? const <int>[];
    final files = task.files;

    Widget infoRow(String label, String value, {IconData? icon}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: theme.textColor.withOpacity(0.7)),
              const SizedBox(width: 8),
            ],
            SizedBox(
              width: 150,
              child: Text(
                label,
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(color: theme.textColor, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    Widget section(String title, Widget child) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.textFieldColor.withOpacity(0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section(
          'Szczegóły',
          Column(
            children: [
              infoRow(
                'Status',
                task.isCompleted == true ? 'Ukończone' : 'W toku',
                icon: Icons.task_alt,
              ),
              infoRow(
                'Priorytet',
                task.priority ?? '—',
                icon: Icons.flag_outlined,
              ),
              infoRow(
                'Termin',
                _formatDate(task.deadline),
                icon: Icons.event_outlined,
              ),
              infoRow(
                'Początek',
                _formatDate(task.dateStart),
                icon: Icons.play_circle_outline,
              ),
              infoRow(
                'Koniec',
                _formatDate(task.dateEnd),
                icon: Icons.stop_circle_outlined,
              ),
              infoRow(
                'Komentarze',
                '${task.commentsCount ?? 0}',
                icon: Icons.comment_outlined,
              ),
              infoRow(
                'Checklista',
                checklistTotal == 0
                    ? '—'
                    : '$checklistCompleted / $checklistTotal',
                icon: Icons.checklist_outlined,
              ),
            ],
          ),
        ),
        if ((task.description ?? '').trim().isNotEmpty)
          section(
            'Opis',
            SelectableText(
              task.description ?? '',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        if (members.isNotEmpty)
          section(
            'Przypisani pracownicy',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  members
                      .map(
                        (id) => Chip(
                          label: Text('User #$id'),
                          backgroundColor: theme.adPopBackground,
                          labelStyle: TextStyle(color: theme.textColor),
                        ),
                      )
                      .toList(),
            ),
          ),
        if (labels.isNotEmpty)
          section(
            'Etykiety',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  labels
                      .map(
                        (id) => Chip(
                          label: Text('Label #$id'),
                          backgroundColor: theme.adPopBackground,
                          labelStyle: TextStyle(color: theme.textColor),
                        ),
                      )
                      .toList(),
            ),
          ),
        if (files != null && files.isNotEmpty)
          section(
            'Załączniki',
            Column(
              children:
                  files.map((file) {
                    final name = (file.filename ?? '').trim();
                    final url = (file.file ?? '').trim();
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.attach_file, color: theme.textColor),
                      title: SelectableText(
                        name.isNotEmpty ? name : 'Załącznik',
                        style: TextStyle(color: theme.textColor),
                      ),
                      subtitle:
                          url.isEmpty
                              ? null
                              : SelectableText(
                                url,
                                maxLines: 2,
                                style: TextStyle(
                                  color: theme.textColor.withOpacity(0.65),
                                  fontSize: 11,
                                ),
                              ),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }
}
