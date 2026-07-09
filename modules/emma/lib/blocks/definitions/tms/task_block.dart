import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:core/platform/navigation_service.dart';
import 'package:core/platform/route_constant.dart';
import 'package:tms_app/todo/models/tasks_model.dart';
import 'package:tms_app/todo/view/task_pup_up.dart';

import 'package:emma/blocks/core/block_definition.dart';
import 'package:emma/blocks/core/block_descriptor.dart';
import 'package:emma/blocks/definitions/shared/block_ui.dart';

class TmsTaskBlockDefinition extends EmmaBlockDefinition {
  const TmsTaskBlockDefinition();

  @override
  String get key => 'tms_task';

  @override
  bool supports(EmmaBlockDescriptor block) {
    return block.type == EmmaBlockType.tmsTask;
  }

  @override
  Widget buildBlock({
    required BuildContext context,
    required WidgetRef ref,
    required EmmaBlockDescriptor block,
    required double maxWidth,
    required String messageId,
  }) {
    return _TmsTaskBlockCard(
      block: block,
      maxWidth: maxWidth,
    );
  }
}

class _TmsTaskPayload {
  final Map<String, dynamic> rawTask;
  final String title;
  final String operation;
  final int? taskId;
  final int? projectId;
  final int? progressId;
  final String name;
  final String description;
  final String projectName;
  final String progressName;
  final String? priority;
  final String? deadline;
  final bool isCompleted;
  final Map<String, dynamic> meta;

  const _TmsTaskPayload({
    required this.rawTask,
    required this.title,
    required this.operation,
    required this.taskId,
    required this.projectId,
    required this.progressId,
    required this.name,
    required this.description,
    required this.projectName,
    required this.progressName,
    required this.priority,
    required this.deadline,
    required this.isCompleted,
    required this.meta,
  });

  factory _TmsTaskPayload.fromBlock(EmmaBlockDescriptor block) {
    final root = block.raw;
    final taskRaw = root['task'] is Map
        ? Map<String, dynamic>.from(root['task'] as Map)
        : Map<String, dynamic>.from(root);

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    final metaRaw = root['meta'];
    final meta = metaRaw is Map
        ? Map<String, dynamic>.from(metaRaw)
        : <String, dynamic>{};

    return _TmsTaskPayload(
      rawTask: taskRaw,
      title: (root['title'] ?? 'Task').toString(),
      operation: (root['operation'] ?? 'update').toString(),
      taskId: parseInt(taskRaw['id'] ?? root['task_id']),
      projectId: parseInt(taskRaw['project_id']),
      progressId: parseInt(taskRaw['progress_id']),
      name: (taskRaw['name'] ?? root['name'] ?? 'Zadanie').toString(),
      description: (taskRaw['description'] ?? '').toString(),
      projectName: (taskRaw['project_name'] ?? '').toString(),
      progressName: (taskRaw['progress_name'] ?? '').toString(),
      priority: taskRaw['priority']?.toString(),
      deadline: taskRaw['deadline']?.toString(),
      isCompleted: taskRaw['is_completed'] == true,
      meta: meta,
    );
  }
}

class _TmsTaskBlockCard extends ConsumerWidget {
  final EmmaBlockDescriptor block;
  final double maxWidth;

  const _TmsTaskBlockCard({
    required this.block,
    required this.maxWidth,
  });

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Color _priorityColor(String? priority) {
    switch ((priority ?? '').toUpperCase()) {
      case 'L':
        return Colors.lightBlueAccent;
      case 'M':
        return Colors.orangeAccent;
      case 'H':
        return Colors.deepOrangeAccent;
      default:
        return Colors.white54;
    }
  }

  String _priorityLabel(String? priority) {
    switch ((priority ?? '').toUpperCase()) {
      case 'L':
        return 'priority_low'.tr;
      case 'M':
         return 'priority_medium'.tr;
      case 'H':
         return 'priority_high'.tr;
      default:
        return '-';
    }
  }

  String _operationLabel(_TmsTaskPayload payload) {
    switch (payload.operation) {
      case 'create':
        return 'emma_created_task'.tr;
      case 'move':
        return 'emma_moved_task'.tr;
      case 'complete':
        return 'emma_completed_task'.tr;
      case 'reopen':
        return 'emma_reopened_task'.tr;
      case 'update':
      default:
        return 'emma_updated_task'.tr;
    }
  }

  Future<void> _openTask(
    BuildContext context,
    WidgetRef ref,
    _TmsTaskPayload payload,
  ) async {
    if (payload.rawTask.isEmpty) {
      return _openBoard(context, ref, payload);
    }

    try {
      final task = Tasks.fromJson(payload.rawTask);
      final isMobile = MediaQuery.of(context).size.width < 650;

      if (isMobile) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) => TaskDetailsPopup(
                task: task,
                isMobile: true,
                scrollController: scrollController,
              ),
            );
          },
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: TaskDetailsPopup(
            task: task,
            isMobile: false,
          ),
        ),
      );
    } catch (_) {
      await _openBoard(context, ref, payload);
    }
  }

  Future<void> _openBoard(
    BuildContext context,
    WidgetRef ref,
    _TmsTaskPayload payload,
  ) async {
    ref.read(navigationService).pushNamedScreen(Routes.proTodo);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          payload.projectName.trim().isEmpty
              ? 'tms_opened'.tr
              : '${'board_opened'.tr}: ${payload.projectName}'
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = _TmsTaskPayload.fromBlock(block);
    final accent = payload.isCompleted
        ? Colors.greenAccent
        : _priorityColor(payload.priority);

    final deadline = _formatDate(payload.deadline);
    final prevProject = (payload.meta['previous_project_name'] ?? '').toString();
    final prevProgress = (payload.meta['previous_progress_name'] ?? '').toString();

    return EmmaBlockCardShell(
      maxWidth: maxWidth,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _operationLabel(payload),
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                payload.isCompleted
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payload.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if ((payload.priority ?? '').isNotEmpty)
                EmmaTag(
                  label: _priorityLabel(payload.priority),
                  color: _priorityColor(payload.priority),
                ),
            ],
          ),
          if (payload.projectName.isNotEmpty || payload.progressName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (payload.projectName.isNotEmpty) '${'board'.tr}:  ${payload.projectName}',
                if (payload.progressName.isNotEmpty) '${'column'.tr}: ${payload.progressName}',
              ].join(' · '),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
          if ((prevProject.isNotEmpty || prevProgress.isNotEmpty) &&
              payload.operation == 'move') ...[
            const SizedBox(height: 4),
            Text(
              [
                if (prevProject.isNotEmpty) '${'from_board'.tr}: $prevProject',
                if (prevProgress.isNotEmpty) '${'from_column'.tr}: $prevProgress',
              ].join(' · '),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
          if (deadline.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${'deadline'.tr}: $deadline',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
          if (payload.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              payload.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withAlpha(185),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              EmmaActionPill(
                label: 'open'.tr,
                icon: Icons.open_in_new,
                onTap: () => _openTask(context, ref, payload),
              ),
              EmmaActionPill(
                label: 'board'.tr,
                icon: Icons.view_kanban_outlined,
                onTap: () => _openBoard(context, ref, payload),
              ),
            ],
          ),
        ],
      ),
    );
  }
}